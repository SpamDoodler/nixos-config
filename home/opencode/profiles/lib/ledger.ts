// The research ledger as a state machine. Every transition is validated here, so the orchestrator cannot
// skip a check, use the wrong checker, or forget to log an outcome. Each tool result ends with a short
// footer (one status line; the rules only when something is overdue), which keeps the reminder at the end
// of the context without bloating it.
import { existsSync } from "node:fs"
import { LADDER, MATCHED_PROBES, STARTABLE, workspacePath, type Config, type Tier, type VerifyLevel, type Verdict } from "./core.ts"

export type Status = "pending" | "running" | "verifying" | "adjudicating" | "redteam" | "done" | "failed" | "blocked" | "split" | "dropped"
const TERMINAL: Status[] = ["done", "split", "dropped"]

export type CheckRole = "regular" | "down" | "up"
export interface CheckRun { tier: Tier; role: CheckRole; verdict?: Verdict; session?: string }
export interface Adjudication { kind: "arbitrate" | "audit" | "reconcile"; tier: Tier; agent: string; fixable?: boolean; note?: string }
export interface Attempt { tier: Tier; dispatched: string; checkLaunched?: boolean; repairUsed?: boolean; verdict?: Verdict; routes?: string[]; checks?: CheckRun[]; adj?: Adjudication }
export interface Probe { tier: Tier; kind: "luna" | "shadow" | "paired"; workerFinished?: boolean; checkLaunched?: boolean; done?: boolean; result?: string }
export interface Task {
  id: string; title: string; type: string; tags: string[]
  difficulty: number; origDifficulty: number; lo: number; hi: number
  gradingBaseline?: number; gradeReason?: string
  priority: number; verify: VerifyLevel; deps: string[]; status: Status; tier?: Tier
  failedTiers: Tier[]; attempts: Attempt[]; probes: Probe[]; lastVerdict?: Verdict
  card?: string; link?: string; notes: string[]; created: string; updated: string
}
export interface Gate { kind: string; t: string; doneAt: number; note?: string }
export interface Ledger { tasks: Map<string, Task>; gates: Gate[]; rounds: { t: string; active: number; cap: number }[]; calls: number; adjudications: number }

export function parseRange(r: string | undefined, d: number): [number, number] {
  const m = /^\s*([1-5])\s*[-–]\s*([1-5])\s*$/.exec(r ?? "")
  if (!m) return [d, d]
  const a = Math.min(+m[1], +m[2]), b = Math.max(+m[1], +m[2])
  return [Math.min(a, d), Math.max(b, d)]
}

export function fold(events: any[]): Ledger {
  const tasks = new Map<string, Task>()
  const gates: Gate[] = []
  const rounds: Ledger["rounds"] = []
  let adjudications = 0
  const doneCount = () => [...tasks.values()].filter((t) => t.status === "done").length
  for (const e of events) {
    if (["add", "update", "dispatch", "check", "verdict"].includes(e.op) && !e.probe)
      for (let i = gates.length - 1; i >= 0; i--)
        if (["integration", "final"].includes(gates[i].kind)) gates.splice(i, 1)
    const t = e.id ? tasks.get(e.id) : undefined
    const note = () => { if (t && e.note) t.notes.push(`${String(e.t).slice(0, 16)} ${e.note}`); if (t) t.updated = e.t }
    switch (e.op) {
      case "add": {
        const d = e.difficulty ?? 3
        const [lo, hi] = parseRange(e.difficulty_range, d)
        tasks.set(e.id, {
          id: e.id, title: e.title ?? e.id, type: e.type ?? "other", tags: e.tags ?? [], difficulty: e.working_difficulty ?? d, origDifficulty: d, lo, hi,
          gradingBaseline: e.working_difficulty ?? d, gradeReason: e.grade_reason,
          priority: e.priority ?? 2, verify: e.verify ?? "V1", deps: e.deps ?? [], status: "pending", failedTiers: [], attempts: [], probes: [],
          card: e.card, link: e.link, notes: [], created: e.t, updated: e.t,
        })
        break
      }
      case "update":
        if (!t) break
        if (e.status) t.status = e.status
        if (e.difficulty) { t.difficulty = e.difficulty; t.gradingBaseline = e.difficulty; t.gradeReason = e.note ?? "manual regrade" }
        if (e.priority) t.priority = e.priority
        if (e.verify) t.verify = e.verify
        note()
        break
      case "regrade":
        if (t) {
          t.difficulty = e.difficulty
          t.gradeReason = e.note
          t.notes.push(`difficulty ${e.previous} → ${e.difficulty}: ${e.note}`)
        }
        break
      case "dispatch":
        if (!t) break
        t.status = "running"; t.tier = e.tier
        t.attempts.push({ tier: e.tier, dispatched: e.t, routes: e.routes })
        for (const p of e.probes ?? []) t.probes.push({ tier: p.tier, kind: p.kind })
        note()
        break
      case "check":
        if (!t) break
        if (e.probe) { const p = t.probes.find((x) => x.tier === e.probe && !x.done); if (p) p.checkLaunched = true }
        else { t.status = "verifying"; const a = t.attempts.at(-1); if (a) { a.checkLaunched = true; a.checks = e.checks; a.adj = undefined } }
        t.updated = e.t
        break
      case "probe_finished": {
        const p = t?.probes.find((x) => x.tier === e.probe && !x.done)
        if (p) p.workerFinished = true
        break
      }
      case "verdict": {
        if (!t) break
        if (e.probe) { const p = t.probes.find((x) => x.tier === e.probe && !x.done); if (p) { p.done = true; p.result = e.verdict } break }
        const a = t.attempts.at(-1)
        if (a && e.checks) a.checks = e.checks
        if (e.unresolved) { t.status = "blocked"; if (a) a.adj = undefined; note(); break }
        if (e.adjudicate) { adjudications++; t.status = "adjudicating"; if (a) a.adj = e.adjudicate; note(); break }
        if (a) a.adj = undefined
        t.lastVerdict = e.verdict
        if (e.repair) { t.status = "running"; if (a) { a.repairUsed = true; a.checkLaunched = false } }
        else {
          if (a) a.verdict = e.verdict
          if (e.verdict === "pass" || e.verdict === "pass_with_issues") t.status = e.redteamPending ? "redteam" : "done"
          else if (e.verdict === "wrong_question") t.status = "blocked"
          else { t.status = "failed"; if (t.tier && !t.failedTiers.includes(t.tier)) t.failedTiers.push(t.tier) }
        }
        note()
        break
      }
      case "gate":
        if (e.kind === "redteam" && t?.status === "redteam") {
          t.status = e.verdict === "pass" ? "done" : "blocked"
          note()
        }
        gates.push({ kind: e.kind, t: e.t, doneAt: doneCount(), note: e.note })
        break
      case "status": rounds.push({ t: e.t, active: e.active ?? 0, cap: e.cap ?? 5 }); break
    }
  }
  return { tasks, gates, rounds, calls: events.length, adjudications }
}

// ---------- graph ----------
export function downstream(tasks: Map<string, Task>) {
  const kids = new Map<string, string[]>()
  for (const t of tasks.values()) for (const d of t.deps) kids.set(d, [...(kids.get(d) ?? []), t.id])
  const memo = new Map<string, number>()
  const depthOf = (id: string, stack: Set<string>): number => {
    if (memo.has(id)) return memo.get(id)!
    if (stack.has(id)) return 0
    stack.add(id)
    const v = 1 + Math.max(0, ...(kids.get(id) ?? []).map((k) => depthOf(k, stack)))
    stack.delete(id); memo.set(id, v)
    return v
  }
  const out = new Map<string, { depth: number; unlocks: number }>()
  for (const id of tasks.keys()) {
    const seen = new Set<string>(); const q = [...(kids.get(id) ?? [])]
    while (q.length) { const k = q.pop()!; if (seen.has(k)) continue; seen.add(k); q.push(...(kids.get(k) ?? [])) }
    out.set(id, { depth: depthOf(id, new Set()), unlocks: seen.size })
  }
  return out
}

export function ready(tasks: Map<string, Task>): Task[] {
  const ds = downstream(tasks)
  return [...tasks.values()]
    .filter((t) => t.status === "pending" && t.deps.every((d) => tasks.get(d)?.status === "done"))
    .sort((a, b) => { const A = ds.get(a.id)!, B = ds.get(b.id)!; return a.priority - b.priority || B.depth - A.depth || B.unlocks - A.unlocks || a.difficulty - b.difficulty })
}

/** Main work slots: one per running task, plus each extra route or replica worker. */
export function active(L: Ledger) {
  let n = 0
  for (const t of L.tasks.values()) {
    if (t.status !== "running" && t.status !== "verifying" && t.status !== "adjudicating") continue
    const a = t.attempts.at(-1)
    n += Math.max(1, a?.routes?.length ?? 0) + (t.verify === "V3" || t.verify === "V4" ? 1 : 0)
  }
  return n
}
export function probesActive(L: Ledger) {
  let n = 0
  for (const t of L.tasks.values()) n += t.probes.filter((p) => !p.done && !p.workerFinished).length
  return n
}

export function stats(L: Ledger, cfg: Config) {
  const live = [...L.tasks.values()].filter((t) => t.status !== "dropped" && t.status !== "split")
  const ids = new Set(live.map((t) => t.id))
  const level = new Map<string, number>()
  const lev = (t: Task, stack = new Set<string>()): number => {
    if (level.has(t.id)) return level.get(t.id)!
    if (stack.has(t.id)) return 1
    stack.add(t.id)
    const v = 1 + Math.max(0, ...t.deps.filter((d) => ids.has(d)).map((d) => lev(L.tasks.get(d)!, stack)))
    level.set(t.id, v)
    return v
  }
  for (const t of live) lev(t)
  const critical = Math.max(0, ...level.values())
  const widths = new Map<number, number>()
  for (const v of level.values()) widths.set(v, (widths.get(v) ?? 0) + 1)
  const ds = downstream(L.tasks)
  const hubThreshold = Math.max(4, Math.ceil(live.length / 4))
  return {
    tasks: live.length, criticalPath: critical, parallelism: critical ? live.length / critical : 0,
    maxWidth: Math.max(0, ...widths.values()),
    widths: [...widths.entries()].sort((a, b) => a[0] - b[0]).map(([k, v]) => `L${k}:${v}`).join(" "),
    hubs: live.filter((t) => (ds.get(t.id)?.unlocks ?? 0) >= hubThreshold && t.status !== "done").map((t) => `${t.id} (unlocks ${ds.get(t.id)!.unlocks})`),
    fanIn: live.filter((t) => t.deps.length >= 4).map((t) => `${t.id} (${t.deps.length} deps)`),
    utilization: L.rounds.length ? L.rounds.reduce((a, r) => a + Math.min(1, r.active / r.cap), 0) / L.rounds.length : NaN,
  }
}

export function renderStats(s: ReturnType<typeof stats>, cfg: Config) {
  const tips: string[] = []
  if (s.tasks >= 8 && s.parallelism < cfg.parallelism_target)
    tips.push(`Parallelism ${s.parallelism.toFixed(1)} is below ${cfg.parallelism_target}: cut long chains with contract tasks, split by case or parameter range, run checks and literature beside the main line (decomposition.md).`)
  if (s.hubs.length) tips.push(`Bottlenecks: ${s.hubs.join(", ")}: prioritise, route higher, or split so part unblocks early.`)
  if (s.fanIn.length) tips.push(`Integration points: ${s.fanIn.join(", ")}: does each need all its inputs?`)
  return [
    `Graph: ${s.tasks} live tasks, critical path ${s.criticalPath}, parallelism ${s.parallelism.toFixed(1)} (target ${cfg.parallelism_target}), widest level ${s.maxWidth} [${s.widths}]. Slot utilisation: ${Number.isFinite(s.utilization) ? Math.round(100 * s.utilization) + "%" : "no rounds yet"}.`,
    ...tips,
  ].join("\n")
}

// ---------- policy ----------
export function nextTier(t: Tier): Tier | null {
  return [...STARTABLE, "astra" as const].find((tier) => tierIdx(tier) > tierIdx(t)) ?? null
}
export const tierIdx = (t: Tier) => LADDER.indexOf(t)

/** Check one level up: luna by terra, terra by sol, sol by sol (P1: astra), astra by sol. */
export function checkerPolicy(worker: Tier, priority: number, cfg: Config): { agent: string; tier: Tier; allowed: Tier[] } {
  switch (worker) {
    case "luna": return { agent: "r-verifier-t", tier: "terra-low", allowed: ["terra-low", "sol-low", "sol", "astra"] }
    case "terra-low": return { agent: "r-verifier-s-low", tier: "sol-low", allowed: ["sol-low", "sol", "astra"] }
    case "terra": return { agent: "r-verifier-s", tier: "sol", allowed: ["sol", "astra"] }
    case "sol-low": return { agent: "r-verifier-s", tier: "sol", allowed: ["sol", "astra"] }
    case "sol": return priority === 1 && cfg.astra_checks_p1_sol ? { agent: "r-verifier-a", tier: "astra", allowed: ["astra"] } : { agent: "r-verifier-s", tier: "sol", allowed: ["sol", "astra"] }
    case "astra":
    case "astra-max": return { agent: "r-verifier-s", tier: "sol", allowed: ["sol"] }
  }
}
export const checkMode = (v: VerifyLevel) => (v === "V1" ? "check" : v === "V2" ? "independent" : "compare")

export function tierGuard(t: Task, tier: Tier): string | null {
  if (tier === "terra") return "Terra Medium is benchmark-only."
  if (tier !== "astra" && tier !== "astra-max") return null
  if (t.priority !== 1) return `astra is reserved for priority-1 tasks; ${t.id} is priority ${t.priority}. Re-scope, split or drop instead, or raise the priority with a note.`
  if (!t.failedTiers.includes("sol")) return `astra is escalation-only: ${t.id} has no verified sol failure yet.`
  if (tier === "astra-max" && !t.failedTiers.includes("astra")) return `${t.id} has no verified Astra xhigh failure yet.`
  return null
}

export const cardPath = (dir: string, t: Task) => {
  const parts = (t.card ?? `research/tasks/${t.id}/card.md`).split("/")
  if (parts.length < 4 || parts[0] !== "research" || parts[1] !== "tasks" || parts.at(-1) !== "card.md")
    throw new Error("Task cards must be under research/tasks/<id>/card.md")
  return workspacePath(dir, ...parts)
}
export const cardExists = (dir: string, t: Task) => existsSync(cardPath(dir, t))
export const taskFolder = (dir: string, t: Task) => {
  cardPath(dir, t)
  return (t.card ?? `research/tasks/${t.id}/card.md`).replace(/\/card\.md$/, "")
}

/**
 * Probes collect benchmark data without affecting the task. Luna probes run where luna's pass rate on this
 * kind of task is still uncertain (little data, a middling estimate, or a wide difficulty range); luna costs
 * almost nothing, and the probe is checked cheaply against the verified main result. Shadows (one tier
 * below the routed tier) run on a share of eligible tasks to measure over-allocation directly.
 */
export function wantsProbes(t: Task, freeProbeSlots: number): Probe[] {
  if (t.attempts.length || freeProbeSlots < MATCHED_PROBES.length) return []
  return MATCHED_PROBES.map((tier) => ({ tier, kind: "paired" }))
}

// ---------- cross-checks: a second checker one model below or above the regular one ----------
const VAGENT: Partial<Record<Tier, string>> = { luna: "r-verifier-l", "terra-low": "r-verifier-t", "sol-low": "r-verifier-s-low", sol: "r-verifier-s", astra: "r-verifier-a" }
export const verifierAgent = (t: Tier) => VAGENT[t]

/**
 * Extra checks for benchmark data. Below: cheap, often. Above: rare. sol and astra are paired only on
 * central claims: astra's checks get a sol re-check on V4 (headline) claims, or on all P1 in max mode;
 * sol's checks get an astra re-check only on P1/P2 work, at a low rate.
 */
export function checkProbes(t: Task, regular: Tier, cfg: Config, rnd: () => number): CheckRun[] {
  const out: CheckRun[] = []
  if (regular === "terra-low") {
    if (rnd() < cfg.check_down_rate.terra) out.push({ tier: "luna", role: "down" })
    if (rnd() < cfg.check_up_rate.terra) out.push({ tier: "sol", role: "up" })
  } else if (regular === "sol") {
    if (rnd() < cfg.check_down_rate.sol) out.push({ tier: "terra-low", role: "down" })
    if (t.priority <= 2 && rnd() < cfg.check_up_rate.sol) out.push({ tier: "astra", role: "up" })
  } else if (regular === "astra") {
    if (cfg.astra_down_probe === "p1" || (cfg.astra_down_probe === "headline" && t.verify === "V4")) out.push({ tier: "sol", role: "down" })
  }
  return out
}

export const vclass = (v?: string) => (v === "pass" || v === "pass_with_issues" ? "pass" : v === "wrong_question" ? "wq" : v ? "fail" : "")

/**
 * What to do when checkers disagree:
 * - luna vs terra: luna is counted wrong; a sampled share is audited by sol to measure that bias.
 * - terra vs sol: astra adjudicates.
 * - sol vs astra: both reconsider with the other's report (follow-ups to their own sessions).
 * Beyond the per-project budget, the regular verdict stands and the conflict is logged as unresolved.
 */
export function resolution(regular: CheckRun, extras: CheckRun[], used: number, cfg: Config, rnd: () => number): { adj?: Adjudication; unresolved: boolean; final?: Verdict } {
  const dis = extras.filter((x) => vclass(x.verdict) !== vclass(regular.verdict))
  if (!dis.length) return { unresolved: false }
  // A checker stronger than everyone in the disagreement has already ruled: its verdict decides, at no extra cost.
  const top = Math.max(LADDER.indexOf(regular.tier), ...dis.map((x) => LADDER.indexOf(x.tier)))
  const stronger = extras.filter((x) => LADDER.indexOf(x.tier) > top).sort((a, b) => LADDER.indexOf(b.tier) - LADDER.indexOf(a.tier))[0]
  if (stronger?.verdict) return { unresolved: false, final: stronger.verdict }
  const pair = (a: Tier, b: Tier) => dis.some((x) => (regular.tier === a && x.tier === b) || (regular.tier === b && x.tier === a))
  const budget = used < cfg.max_adjudications
  if (pair("sol", "astra")) return budget ? { adj: { kind: "reconcile", tier: "astra", agent: "r-verifier-a + r-verifier-s" }, unresolved: false } : { unresolved: true }
  if (pair("terra-low", "sol")) return budget ? { adj: { kind: "arbitrate", tier: "astra", agent: "r-verifier-a" }, unresolved: false } : { unresolved: true }
  if (pair("luna", "terra-low")) return budget && rnd() < cfg.luna_audit_rate ? { adj: { kind: "audit", tier: "sol", agent: "r-verifier-s" }, unresolved: false } : { unresolved: false }
  return { unresolved: false }
}

// ---------- audit and footer ----------
export function audit(L: Ledger, cfg: Config) {
  const must: string[] = [], should: string[] = []
  const tasks = [...L.tasks.values()]
  const done = tasks.filter((t) => t.status === "done").length
  const dispatched = tasks.some((t) => t.attempts.length)
  const has = (k: string) => L.gates.some((g) => g.kind === k)
  if (dispatched && !has("premortem")) must.push("pre-mortem missing: r-skeptic premortem, then `ledger gate kind=premortem`")
  for (const t of tasks) {
    const a = t.attempts.at(-1)
    if (t.status === "verifying" && a && !a.checkLaunched) must.push(`${t.id}: launch its checker (\`ledger check id=${t.id}\`)`)
    if (t.status === "adjudicating" && a?.adj) should.push(`${t.id} awaits ${a.adj.kind} (${a.adj.agent}); then \`ledger adjudicate id=${t.id}\`.`)
    if (t.status === "redteam") must.push(`${t.id}: run r-redteam and record the task-scoped gate before using the result`)
    if (t.status === "failed") must.push(`${t.id} failed at ${t.tier}: \`ledger dispatch id=${t.id}\` or set split/dropped/blocked with a note`)
    for (const p of t.probes) if (!p.done && TERMINAL.includes(t.status)) should.push(`${t.id}: check its ${p.tier} probe (\`ledger check id=${t.id} probe=${p.tier}\`).`)
  }
  const lastZoom = [...L.gates].reverse().find((g) => g.kind === "zoomout" || g.kind === "premortem")
  if (dispatched && done - (lastZoom?.doneAt ?? 0) >= cfg.gate_every) must.push(`zoom-out due (${done - (lastZoom?.doneAt ?? 0)} verified since the last): r-skeptic zoomout, then \`ledger gate kind=zoomout\``)
  for (const t of tasks.filter((t) => t.status === "blocked" && t.lastVerdict === "wrong_question"))
    if (!L.gates.some((g) => (g.kind === "zoomout" || g.kind === "reframe") && g.t > t.updated)) must.push(`${t.id} returned WRONG_QUESTION: zoom-out before anything else`)
  const r = ready(L.tasks), act = active(L)
  if (r.length && act < cfg.concurrency) should.push(`${Math.min(r.length, cfg.concurrency - act)} slot(s) free, ${r.length} ready: dispatch.`)
  const s = stats(L, cfg)
  if (s.tasks >= 8 && s.parallelism < cfg.parallelism_target && !has("structure")) should.push(`parallelism ${s.parallelism.toFixed(1)} < ${cfg.parallelism_target}: \`ledger stats\`, restructure or \`ledger gate kind=structure\`.`)
  const open = tasks.filter((t) => !TERMINAL.includes(t.status) && t.status !== "blocked")
  if (dispatched && tasks.length && !open.length) {
    if (!has("integration")) must.push("all tasks settled: integration check (r-verifier-s, r-verifier-t), then `ledger gate kind=integration`")
    else if (!has("final")) must.push("write REPORT.md, r-strategist final, then `ledger gate kind=final`")
  }
  return { must, should }
}

export const RULES = "Rules: results count only after `ledger check` -> the checkers it names -> `ledger verdict` (and `ledger adjudicate` if checkers disagree); start at the routed tier, astra only after sol failed on P1; one local repair by follow-up, else escalate with the failure summary; keep slots full with independent tasks; end your turn while workers run, finish each round with `ledger status`."

export function footer(L: Ledger, cfg: Config) {
  const tasks = [...L.tasks.values()]
  const c = (s: Status) => tasks.filter((t) => t.status === s).length
  const a = audit(L, cfg)
  const lines = [
    "",
    `[ledger] done ${c("done")} · running ${c("running")} · verifying ${c("verifying") + c("adjudicating")} · ready ${ready(L.tasks).length} · failed ${c("failed")} · blocked ${c("blocked")} · slots ${active(L)}/${cfg.concurrency} · probes ${probesActive(L)}/${cfg.probe_slots} · parallelism ${stats(L, cfg).parallelism.toFixed(1)}`,
  ]
  if (a.must.length) lines.push(`REQUIRED NOW: ${a.must.join("; ")}.`)
  if (a.should.length) lines.push(`next: ${a.should.join(" ")}`)
  if (a.must.length || L.calls % 10 === 0) lines.push(RULES)
  return lines.join("\n")
}

export function render(L: Ledger) {
  const r = new Set(ready(L.tasks).map((t) => t.id))
  const order: Status[] = ["running", "verifying", "adjudicating", "redteam", "pending", "failed", "blocked", "done", "split", "dropped"]
  const tasks = [...L.tasks.values()]
  return [
    "# Task ledger (generated from ledger.jsonl; do not edit by hand)", "",
    order.map((s) => `${s}: ${tasks.filter((t) => t.status === s).length}`).join(" | "), "",
    "| id | status | prio | type | working grade (original) | verify | attempts | probes | deps | title | last note |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ...tasks
      .sort((a, b) => order.indexOf(a.status) - order.indexOf(b.status) || a.id.localeCompare(b.id))
      .map((t) => `| ${t.id} | ${t.status}${r.has(t.id) ? " (ready)" : ""} | P${t.priority} | ${t.type}${t.tags.length ? ` [${t.tags.join(",")}]` : ""} | ${t.difficulty} (${t.origDifficulty}${t.lo === t.hi ? "" : `; range ${t.lo}-${t.hi}`}) | ${t.verify} | ${t.attempts.map((a) => `${a.tier}${a.routes ? `x${a.routes.length}` : ""}:${a.verdict ?? "…"}${a.repairUsed ? "+r" : ""}`).join(" ")} | ${t.probes.map((p) => `${p.tier}${p.done ? "" : "…"}`).join(" ")} | ${t.deps.join(", ")} | ${t.title.replace(/\|/g, "/")} | ${(t.notes.at(-1) ?? t.gradeReason ?? "").replace(/\|/g, "/")} |`),
    "", "Gates: " + (L.gates.map((g) => `${g.kind}@${g.doneAt}`).join(", ") || "none"), "",
  ].join("\n")
}
