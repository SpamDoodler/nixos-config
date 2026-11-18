import { tool } from "../lib/tool.ts"
import { existsSync } from "node:fs"
import { appendJsonl, appendText, benchPath, ledgerMdPath, ledgerPath, loadConfig, loadOutcomes, now, project, readJsonl, readText, route, STARTABLE, usageAllowance, workspacePath, writeText, type Tier } from "../lib/core.ts"
import { active, audit, cardExists, cardPath, checkMode, checkerPolicy, checkProbes, downstream, fold, footer, needsProbePair, nextTier, probesActive, ready, render, renderStats, resolution, stats, taskFolder, tierGuard, tierIdx, vclass, verifierAgent, wantsProbes, type Attempt, type CheckRun, type Task } from "../lib/ledger.ts"

const TIERS = ["luna", "terra", "sol", "astra"] as const
const VERDICTS = ["pass", "pass_with_issues", "fail", "incomplete", "wrong_question"] as const
const passed = (v?: string) => v === "pass" || v === "pass_with_issues"

export default tool({
  description:
    "Research task ledger and procedure (orchestrator only). Per task: add -> dispatch -> check -> verdict; each result says exactly what to launch or do next. " +
    "If checkers disagree, verdict returns what to launch and `adjudicate` records the outcome. Also: ready, update, gate, status (end of round), stats, audit, view.",
  args: {
    action: tool.schema.enum(["add", "dispatch", "probe_finished", "probe_ungraded", "check", "verdict", "adjudicate", "ready", "update", "gate", "status", "stats", "audit", "view"]),
    tasks: tool.schema.array(tool.schema.object({
      id: tool.schema.string().optional(),
      title: tool.schema.string().describe("One specific line"),
      type: tool.schema.string().describe("lookup|literature|derivation|numerics|code|analysis|explore|other"),
      tags: tool.schema.array(tool.schema.string()).optional().describe("e.g. symbolic, search, long-context, coding, conceptual, multi-step"),
      difficulty: tool.schema.number().int().min(1).max(5).describe("best guess, 1-5"),
      difficulty_range: tool.schema.string().optional().describe('your uncertainty, e.g. "2-4"; omit if sure'),
      priority: tool.schema.number().int().min(1).max(3).optional(),
      verify: tool.schema.enum(["V1", "V2", "V3", "V4"]).optional(),
      deps: tool.schema.array(tool.schema.string()).optional(),
      card: tool.schema.string().optional(),
      link: tool.schema.string().optional(),
    })).optional(),
    id: tool.schema.string().optional(),
    tier: tool.schema.enum(TIERS).optional(),
    routes: tool.schema.number().int().min(2).max(6).optional().describe("dispatch: try N distinct routes in parallel (opt-in, for hard or open tasks)"),
    route_notes: tool.schema.array(tool.schema.string()).optional().describe("dispatch: one line per route saying how it differs"),
    probe: tool.schema.enum(TIERS).optional().describe("check/verdict: this concerns the probe at that tier"),
    verdict: tool.schema.enum(VERDICTS).optional(),
    route_verdicts: tool.schema.array(tool.schema.enum(VERDICTS)).optional().describe("verdict: one per route, in order"),
    checker_tier: tool.schema.enum(TIERS).optional().describe("verdict: the regular checker's tier; adjudicate: the adjudicator's tier"),
    check_verdicts: tool.schema.array(tool.schema.object({ tier: tool.schema.enum(TIERS), verdict: tool.schema.enum(VERDICTS), session: tool.schema.string().optional() })).optional().describe("verdict: verdicts of the extra checkers `check` named"),
    reconcile_verdicts: tool.schema.array(tool.schema.object({ tier: tool.schema.enum(TIERS), verdict: tool.schema.enum(VERDICTS) })).optional().describe("adjudicate (reconcile): each checker's final verdict after seeing the other's report"),
    fixable_local: tool.schema.boolean().optional(),
    worker_session: tool.schema.string().optional(),
    route_sessions: tool.schema.array(tool.schema.string()).optional(),
    checker_session: tool.schema.string().optional(),
    steps: tool.schema.number().optional(),
    status: tool.schema.enum(["pending", "blocked", "split", "dropped"]).optional(),
    priority: tool.schema.number().int().min(1).max(3).optional(),
    verify: tool.schema.enum(["V1", "V2", "V3", "V4"]).optional(),
    difficulty: tool.schema.number().int().min(1).max(5).optional(),
    kind: tool.schema.enum(["premortem", "zoomout", "reframe", "structure", "integration", "redteam", "final"]).optional(),
    note: tool.schema.string().optional(),
    next: tool.schema.string().optional(),
    focus: tool.schema.string().optional().describe("Main problems or claims this round is trying to settle"),
    active_routes: tool.schema.array(tool.schema.string()).optional().describe("Current approaches, with route IDs and what each is testing"),
    changed: tool.schema.string().optional().describe("Material result or decision since the last update, including why a route changed"),
    blockers: tool.schema.string().optional().describe("What is blocked or awaited, and what would unblock it"),
  },
  async execute(a, ctx) {
    const dir = ctx.directory
    const cfg = loadConfig()
    const bench = ctx.modelSet ? benchPath(dir, ctx.modelSet) : undefined
    const benchmark = (event: object) => { if (bench) appendJsonl(bench, event) }
    const outcomes = () => bench ? loadOutcomes(bench, cfg, readJsonl(ledgerPath(dir))) : []
    const log = (e: object) => appendJsonl(ledgerPath(dir), { t: now(), ...e })
    const load = () => fold(readJsonl(ledgerPath(dir)))
    if (readJsonl(ledgerPath(dir)).some((e) => e.op === "update" && e.tier))
      return "REFUSED: this workspace uses a legacy ledger. Preserve it and start a fresh ledger, transferring prior evidence and unfinished tasks explicitly."
    const finish = (msg: string) => { const L = load(); writeText(ledgerMdPath(dir), render(L)); return msg + footer(L, cfg) }
    const L = load()
    const task = a.id ? L.tasks.get(a.id) : undefined
    if (["dispatch", "probe_finished", "probe_ungraded", "check", "verdict", "adjudicate", "update"].includes(a.action) && !task) return finish(`ERROR: unknown or missing task id "${a.id ?? ""}".`)
    const outcomeBase = (t: Task) => ({
      kind: "outcome", t: now(), project: project(dir), task_id: t.id, title: t.title, type: t.type, tags: t.tags,
      difficulty: t.origDifficulty, difficulty_lo: t.lo, difficulty_hi: t.hi, priority: t.priority, checker_tier: a.checker_tier,
      checker_session: a.checker_session, steps: a.steps, note: a.note,
    })

    // One check event per checker, with the final verdict, for the checker benchmark.
    const logChecks = (t: Task, checks: CheckRun[], final: string, resolved_by: string, reconciled?: { tier: string; verdict: string }[]) => {
      for (const c of checks)
        benchmark({ kind: "check", t: now(), project: project(dir), task_id: t.id, type: t.type, tags: t.tags, difficulty: t.origDifficulty, worker_tier: t.tier, checker_tier: c.tier, role: c.role, verdict: c.verdict, final: resolved_by === "unresolved" ? undefined : final, resolved_by, checker_session: c.session })
      for (const r of reconciled ?? [])
        benchmark({ kind: "check", t: now(), project: project(dir), task_id: t.id, type: t.type, difficulty: t.origDifficulty, worker_tier: t.tier, checker_tier: r.tier, role: "reconcile", verdict: r.verdict, final, resolved_by })
    }
    // After the final verdict is known: repair, log the worker outcome, and say what is next.
    const settle = (t: Task, att: Attempt, verdict: string, fixable: boolean, alreadyLogged: boolean): string => {
      if (!alreadyLogged) {
        if ((verdict === "fail" || verdict === "incomplete") && fixable && !att.repairUsed) {
          log({ op: "verdict", id: t.id, verdict, repair: true, note: a.note })
          return finish(`REPAIR ${t.id}: send the checker's issue list as a follow-up to worker session ${a.worker_session ?? "(its sessionID)"}; when it reports, \`ledger check id=${t.id}\` again. Next failure escalates.`)
        }
        const seconds = Math.round((Date.now() - Date.parse(att.dispatched)) / 1000)
        benchmark({ ...outcomeBase(t), tier: t.tier, attempt: t.attempts.length, repaired: !!att.repairUsed, verdict, verify_level: t.verify, worker_session: a.worker_session, seconds })
        log({ op: "verdict", id: t.id, verdict, redteamPending: passed(verdict) && t.verify === "V4", note: a.note })
      }
      const openProbes = t.probes.filter((p) => !p.done).map((p) => p.tier)
      const probeHint = openProbes.length ? ` Then check its probe(s) against this result: ${openProbes.map((p) => `\`ledger check id=${t.id} probe=${p}\``).join(", ")}.` : ""
      if (passed(verdict)) {
        if (t.verify === "V4") return finish(`${t.id} awaits its red-team gate. Run r-redteam and record \`ledger gate kind=redteam id=${t.id} verdict=pass|fail note=...\` before using the result.`)
        const lvl = t.verify === "V1" ? 3 : t.verify === "V2" ? 2 : 1
        return finish(`${t.id} DONE at ${t.tier}${att.routes ? " (multi-route)" : ""}${att.repairUsed ? " after a repair" : ""}. Claims resting on it may cite evidence level ${lvl}.${probeHint}`)
      }
      if (verdict === "wrong_question") return finish(`${t.id} BLOCKED (card cannot be satisfied as written): zoom-out gate before more work on this branch.`)
      const nt = nextTier(t.tier!)
      const t2 = load().tasks.get(t.id)!
      if (nt === "astra" && tierGuard(t2, "astra")) return finish(`${t.id} FAILED at sol, not eligible for astra: re-scope, split or drop it, with a note.`)
      if (!nt) return finish(`${t.id} FAILED at astra: re-scope, split or drop; tell the user if the conclusion depends on it.`)
      return finish(`${t.id} FAILED at ${t.tier}. Append the FAILURE_SUMMARY (max 100 words) to the card, then \`ledger dispatch id=${t.id}\` (-> ${nt}).${probeHint}`)
    }

    switch (a.action) {
      case "add": {
        if (!a.tasks?.length) return finish("ERROR: add needs `tasks`.")
        let n = 0
        const ids: string[] = []
        const pending = []
        for (const t of a.tasks) {
          let id = t.id
          if (!id) do { id = `T${String(++n).padStart(3, "0")}` } while (L.tasks.has(id) || ids.includes(id))
          if (L.tasks.has(id) || ids.includes(id)) return finish(`ERROR: task ${id} already exists.`)
          if (!/^[a-zA-Z0-9][a-zA-Z0-9_-]*$/.test(id)) return finish("REFUSED: invalid task id.")
          cardPath(dir, { ...t, id } as Task)
          pending.push({ op: "add", ...t, id }); ids.push(id)
        }
        const graph = new Map([...L.tasks.values()].map((t) => [t.id, t.deps]))
        for (const event of pending) graph.set(event.id, event.deps ?? [])
        const visited = new Set<string>(), visiting = new Set<string>()
        const checkGraph = (id: string): string | undefined => {
          if (visiting.has(id)) return `dependency cycle at ${id}`
          if (!graph.has(id)) return `unknown dependency ${id}`
          if (visited.has(id)) return
          visiting.add(id)
          for (const dep of graph.get(id)!) {
            const issue = checkGraph(dep)
            if (issue) return issue
          }
          visiting.delete(id)
          visited.add(id)
        }
        for (const id of ids) {
          const issue = checkGraph(id)
          if (issue) return finish(`REFUSED: ${issue}.`)
        }
        for (const event of pending) log(event)
        const L2 = load()
        const noCard = ids.filter((id) => !cardExists(dir, L2.tasks.get(id)!))
        return finish(`Added ${ids.join(", ")}.${noCard.length ? ` Cards still to write: ${noCard.join(", ")}.` : ""}`)
      }

      case "ready": {
        const outs = outcomes()
        const ds = downstream(L.tasks)
        const r = ready(L.tasks)
        if (!r.length) return finish("No ready tasks.")
        return finish([`${Math.max(0, cfg.concurrency - active(L))} free slot(s). Ready, best first:`, ...r.map((t) => {
          const ro = route(outs, t.type, t.difficulty, cfg, { priority: t.priority, depth: ds.get(t.id)!.depth })
          return `${t.id} P${t.priority} ${t.type} d${t.lo === t.hi ? t.difficulty : `${t.difficulty}(${t.lo}-${t.hi})`} ${t.verify} -> ${ro.recommended}${ro.explore ? " (explore)" : ""} [${ro.evidence}]${cardExists(dir, t) ? "" : " NO CARD"} | ${t.title}`
        })].join("\n"))
      }

      case "dispatch": {
        const t = task!
        if (!["pending", "failed"].includes(t.status)) return finish(`REFUSED: ${t.id} is ${t.status}.`)
        if (!L.gates.some((g) => g.kind === "premortem")) return finish("REFUSED: record the pre-mortem gate before dispatch.")
        const overdue = audit(L, cfg).must.find((m) => m.startsWith("zoom-out due") || m.includes("returned WRONG_QUESTION"))
        if (overdue) return finish(`REFUSED: ${overdue}.`)
        const blockers = t.deps.filter((d) => L.tasks.get(d)?.status !== "done")
        if (blockers.length) return finish(`REFUSED: ${t.id} waits on ${blockers.join(", ")}.`)
        if (!cardExists(dir, t)) return finish(`REFUSED: no card at ${cardPath(dir, t)}.`)
        const outs = outcomes()
        const depth = downstream(L.tasks).get(t.id)!.depth
        const ro = route(outs, t.type, t.difficulty, cfg, { priority: t.priority, depth, lowStakes: t.priority === 3 })
        let tier: Tier
        let note: string | undefined
        if (t.status === "failed") {
          const min = nextTier(t.tier!)
          if (!min) return finish(`REFUSED: ${t.id} failed at every tier: re-scope, split or drop it.`)
          tier = (a.tier as Tier) ?? min
          if (tierIdx(tier) < tierIdx(min)) return finish(`REFUSED: after failing at ${t.tier}, ${t.id} goes to ${min} or higher.`)
        } else {
          tier = (a.tier as Tier) ?? ro.recommended
          if (a.tier && a.tier !== ro.recommended && !a.routes) {
            if (!a.note) return finish(`REFUSED: routing says ${ro.recommended}; overriding to ${a.tier} needs a note.`)
            note = `override ${ro.recommended}->${a.tier}: ${a.note}`
          }
          if (!STARTABLE.includes(tier)) return finish(`REFUSED: ${tier} is never a first attempt.`)
          if (!a.routes && t.difficulty >= 4 && tierIdx(tier) < tierIdx("sol")) return finish(`REFUSED: difficulty ${t.difficulty} starts at sol (use routes=N to try several cheaper routes instead).`)
          if (!a.routes && t.priority === 1 && tier === "luna") return finish("REFUSED: priority-1 tasks never start at luna.")
        }
        const guard = tierGuard(t, tier)
        if (guard) return finish(`REFUSED: ${guard}`)
        const folder = taskFolder(dir, t)
        const card = `${folder}/card.md`
        const free = cfg.probe_slots - probesActive(L)
        if (needsProbePair(t) && free < 2)
          return finish(`DEFERRED: ${t.id} needs two free probe slots to start Luna and Terra blind with the main run. Do not start it separately. Record finished probe workers with ledger probe_finished to free slots.`)
        const reserve = !needsProbePair(t) && ready(L.tasks).some((other) => other.id !== t.id && needsProbePair(other) && cardExists(dir, other)) ? 2 : 0
        const probes = wantsProbes(t, tier, depth, cfg, ro.luna, free - reserve, Math.random)
        const frozenCard = `${folder}/probe-card.md`
        const probeLines = () => probes.map((p) =>
          `- subagent r-probe-${p.tier}: "Read ${frozenCard}; independently execute it from the frozen inputs and write ${folder}/probe-${p.tier}/result.md. Do not read the main worker's or other probes' work." (benchmark only)`)
        const freeze = () => {
          if (probes.length) writeText(workspacePath(dir, ...frozenCard.split("/")), readText(cardPath(dir, t)))
        }

        if (a.routes) {
          if (t.verify === "V3" || t.verify === "V4") return finish("REFUSED: multi-route attempts cannot earn V3/V4; dispatch a blind replica instead.")
          const n = a.routes
          const notes = (a.route_notes ?? []).map((s) => s.trim())
          if (notes.length !== n || new Set(notes.map((s) => s.toLowerCase())).size !== n) return finish(`REFUSED: routes=${n} needs ${n} distinct route_notes, one line each saying how the route differs.`)
          const missing = Array.from({ length: n }, (_, k) => `${folder}/routes/r${k + 1}/card.md`).filter((p) => !existsSync(workspacePath(dir, ...p.split("/"))))
          if (missing.length) return finish(`REFUSED: write the route cards first (same goal and acceptance criteria as ${card}, different approach and framing): ${missing.join(", ")}.`)
          if (active(L) + n > cfg.concurrency) return finish(`REFUSED: ${n} routes need ${n} free slots; ${Math.max(0, cfg.concurrency - active(L))} free.`)
          freeze()
          log({ op: "dispatch", id: t.id, tier, routes: notes, probes, note: `routes x${n} at ${tier}${a.note ? ": " + a.note : ""}` })
          return finish([`DISPATCHED ${t.id}: ${n} routes at ${tier}. Launch now:`,
            ...notes.map((r, k) => `- subagent r-worker-${tier}: "Execute ${folder}/routes/r${k + 1}/card.md; write everything to ${folder}/routes/r${k + 1}/."  (${r})`),
            ...probeLines(), "Keep each sessionID for `route_sessions` and the probes."].join("\n"))
        }

        const requiredSlots = t.verify === "V3" || t.verify === "V4" ? 2 : 1
        if (active(L) + requiredSlots > cfg.concurrency) return finish(`REFUSED: ${requiredSlots} main slots required. End your turn; reports will wake you.`)
        freeze()
        log({ op: "dispatch", id: t.id, tier, probes, note })
        const launchCard = probes.length ? frozenCard : card
        const lines = [`DISPATCHED ${t.id} at ${tier} (attempt ${t.attempts.length + 1}). Launch now:`,
          `- subagent r-worker-${tier}: "Execute ${launchCard}; write everything to ${folder}/."${t.status === "failed" ? " (append the checker's FAILURE_SUMMARY to the card first)" : ""}`]
        if (t.verify === "V3" || t.verify === "V4") lines.push(`- subagent r-worker-${tier}: "Blind replication. Execute ${launchCard}; write everything to ${folder}/replica/."`)
        lines.push(...probeLines())
        lines.push("Keep each sessionID for repairs and `worker_session`.")
        return finish(lines.join("\n"))
      }

      case "probe_finished":
      case "probe_ungraded": {
        const p = task!.probes.find((x) => x.tier === a.probe && !x.done)
        if (!p) return finish("REFUSED: no open probe at that tier.")
        if (a.action === "probe_ungraded" && !a.note) return finish("REFUSED: explain why the probe cannot be graded.")
        log({ op: a.action === "probe_finished" ? "probe_finished" : "verdict", id: task!.id, probe: p.tier, verdict: "ungraded", note: a.note })
        return finish(`${task!.id}/${p.tier}: ${a.action === "probe_finished" ? "worker finished; slot freed" : "closed ungraded"}.`)
      }

      case "check": {
        const t = task!
        const folder = taskFolder(dir, t)
        if (a.probe) {
          const p = t.probes.find((x) => x.tier === a.probe && !x.done)
          if (!p) return finish(`REFUSED: ${t.id} has no open ${a.probe} probe.`)
          if (p.checkLaunched) return finish("REFUSED: a probe checker is already assigned.")
          if (t.status !== "done" || !existsSync(workspacePath(dir, ...`${folder}/result.md`.split("/"))))
            return finish("DEFERRED: calibration needs a verified canonical reference (including the V4 gate). Mark the worker finished to free its slot, or close ungraded if no reference is forthcoming.")
          if (!existsSync(workspacePath(dir, ...`${folder}/probe-${p.tier}/result.md`.split("/"))))
            return finish("REFUSED: wait for the probe result artifact or close it ungraded.")
          log({ op: "probe_finished", id: t.id, probe: p.tier })
          log({ op: "check", id: t.id, probe: p.tier })
          const frozen = existsSync(workspacePath(dir, ...`${folder}/probe-card.md`.split("/")))
          return finish(`Launch now: fresh r-verifier-t (Terra): "Mode: reference. Card: ${folder}/${frozen ? "probe-card.md" : "card.md"}. Result: ${folder}/probe-${p.tier}/result.md. Verified reference: ${folder}/result.md. Check reasoning against the card, not just agreement. Write ${folder}/probe-${p.tier}/verdict.md; abstain if unsure." Then record checker_tier=terra, both session IDs, and verdict (or close ungraded). Do not escalate calibration to Sol or Astra.`)
        }
        if (t.status !== "running") return finish(`REFUSED: ${t.id} is ${t.status}; check after the worker reported.`)
        const pol = checkerPolicy(t.tier!, t.priority, cfg)
        const att = t.attempts.at(-1)!
        const resultsRequired = att.routes
          ? att.routes.map((_, k) => `${folder}/routes/r${k + 1}/result.md`)
          : [`${folder}/result.md`, ...(["V3", "V4"].includes(t.verify) ? [`${folder}/replica/result.md`] : [])]
        if (resultsRequired.some((p) => !existsSync(workspacePath(dir, ...p.split("/")))))
          return finish("REFUSED: wait for the worker result artifact(s) before checking.")
        if (att.routes) {
          log({ op: "check", id: t.id, checks: [{ tier: pol.tier, role: "regular" }] })
          const paths = att.routes.map((_, k) => `${folder}/routes/r${k + 1}/result.md`).join(", ")
          return finish(`Launch now: subagent ${pol.agent} (${pol.tier}): "Mode: routes. Card: ${folder}/card.md. Results to judge separately against the card: ${paths}. Give one verdict per route, then say whether the passing routes agree."`)
        }
        const mode = checkMode(t.verify)
        const results = mode === "compare" ? `${folder}/result.md and ${folder}/replica/result.md (after both reported)` : `${folder}/result.md`
        const checkerCard = t.attempts.length === 1 && t.probes.length ? `${folder}/probe-card.md` : `${folder}/card.md`
        const card = existsSync(workspacePath(dir, ...checkerCard.split("/"))) ? checkerCard : `${folder}/card.md`
        const extras = checkProbes(t, pol.tier, cfg, Math.random)
        log({ op: "check", id: t.id, checks: [{ tier: pol.tier, role: "regular" }, ...extras] })
        const lines = [`Launch now:`, `- subagent ${pol.agent} (${pol.tier}, regular check): "Mode: ${mode}. Card: ${card}. Result: ${results}. Verdict file: ${folder}/verdict.md."`]
        for (const x of extras) lines.push(`- subagent ${verifierAgent(x.tier)} (${x.tier}, ${x.role === "down" ? "cross-check one model down" : "cross-check one model up"}, benchmark): "Mode: ${mode}. Card: ${card}. Result: ${results}. Verdict file: ${folder}/verdict-${x.tier}.md. Judge independently; do not read other verdict files."`)
        if (extras.length) lines.push(`Then \`ledger verdict\` with the regular verdict and check_verdicts for ${extras.map((x) => x.tier).join(", ")}.`)
        if (t.verify === "V4") lines.push(`After a pass: r-redteam on the claim, then \`ledger gate kind=redteam id=${t.id} verdict=pass|fail note=...\`.`)
        return finish(lines.join("\n"))
      }

      case "verdict": {
        const t = task!
        if (!a.checker_tier) return finish("ERROR: verdict needs `checker_tier`.")
        if (a.probe) {
          const p = t.probes.find((x) => x.tier === a.probe && !x.done)
          if (!p || !p.checkLaunched || !a.verdict) return finish(`REFUSED: \`ledger check id=${t.id} probe=${a.probe}\` first, and give the verdict.`)
          if (t.status !== "done") return finish("REFUSED: probe grading needs a cleared reference.")
          if (a.checker_tier !== "terra" || !a.checker_session || !a.worker_session || a.checker_session === a.worker_session)
            return finish("REFUSED: give distinct worker and Terra reference checker session IDs.")
          benchmark({ ...outcomeBase(t), tier: p.tier, attempt: 0, shadow: true, probe: p.kind, verdict: a.verdict, verify_level: "V1", worker_session: a.worker_session })
          log({ op: "verdict", id: t.id, probe: p.tier, verdict: a.verdict })
          return finish(`Probe logged: ${p.tier} ${passed(a.verdict) ? "also solved" : "did not solve"} ${t.id}.`)
        }
        const att = t.attempts.at(-1)
        if (t.status !== "verifying" || !att?.checkLaunched) return finish(`REFUSED: ${t.id} is not awaiting a verdict.`)
        const pol = checkerPolicy(t.tier!, t.priority, cfg)
        const issued = att.checks?.find((c) => c.role === "regular")
        if (issued?.tier !== a.checker_tier) return finish(`REFUSED: use the issued regular checker (${issued?.tier ?? pol.tier}).`)
        if (!a.checker_session || (a.worker_session && a.checker_session === a.worker_session))
          return finish("REFUSED: give a checker session ID distinct from the worker session.")
        const seconds = Math.round((Date.now() - Date.parse(att.dispatched)) / 1000)
        let verdict = a.verdict
        if (att.routes) {
          const rv = a.route_verdicts ?? []
          if (rv.length !== att.routes.length) return finish(`REFUSED: give route_verdicts, one per route (${att.routes.length}).`)
          rv.forEach((v, k) => benchmark({ ...outcomeBase(t), tier: t.tier, attempt: t.attempts.length, route: `r${k + 1}: ${att.routes![k]}`, verdict: v, verify_level: t.verify, worker_session: a.route_sessions?.[k], seconds }))
          verdict = rv.find((v) => v === "pass") ?? rv.find((v) => v === "pass_with_issues") ?? (rv.includes("wrong_question") && !rv.some(passed) ? "wrong_question" : "fail")
          log({ op: "verdict", id: t.id, verdict, note: a.note })
          return settle(t, att, verdict!, false, true)
        }
        if (!verdict) return finish("ERROR: verdict needs `verdict`.")
        const regular: CheckRun = { tier: a.checker_tier as Tier, role: "regular", verdict, session: a.checker_session }
        const want = (att.checks ?? []).filter((c) => c.role !== "regular")
        const extras: CheckRun[] = []
        for (const w of want) {
          const v = a.check_verdicts?.find((x) => x.tier === w.tier)
          if (!v) return finish(`REFUSED: give check_verdicts for the cross-check(s) at ${want.map((x) => x.tier).join(", ")} (from ${taskFolder(dir, t)}/verdict-<tier>.md).`)
          extras.push({ ...w, verdict: v.verdict, session: v.session })
        }
        if (extras.length && (new Set([regular, ...extras].map((c) => c.session)).size !== extras.length + 1 ||
            [regular, ...extras].some((c) => !c.session)))
          return finish("REFUSED: give a distinct checker session ID for each cross-check and the regular check.")
        const res = resolution(regular, extras, L.adjudications, cfg, Math.random)
        if (res.final) {
          logChecks(t, [regular, ...extras], res.final, "stronger")
          return settle(t, att, res.final, !!a.fixable_local && !passed(res.final), false)
        }
        if (res.adj) {
          log({ op: "verdict", id: t.id, verdict, checks: [regular, ...extras], adjudicate: { ...res.adj, fixable: !!a.fixable_local }, note: a.note })
          const folder = taskFolder(dir, t)
          const files = [`${folder}/verdict.md (${regular.tier}: ${verdict})`, ...extras.map((x) => `${folder}/verdict-${x.tier}.md (${x.tier}: ${x.verdict})`)].join(", ")
          if (res.adj.kind === "reconcile")
            return finish(`CHECKERS DISAGREE (sol vs astra) on ${t.id}. Reconcile: send each of the two checkers, as a follow-up to its own session, the other's verdict file and ask it to reconsider and state its final verdict. Files: ${files}. Then \`ledger adjudicate id=${t.id} reconcile_verdicts=[{tier, verdict}, {tier, verdict}]\`.`)
          return finish(`CHECKERS DISAGREE on ${t.id}. Launch now: subagent ${res.adj.agent} (${res.adj.tier}): "Mode: adjudicate. Card: ${folder}/card.md. Result: ${folder}/result.md. Conflicting verdicts: ${files}. Decide independently which is right; verdict file: ${folder}/verdict-adjudication.md." Then \`ledger adjudicate id=${t.id} verdict=... checker_tier=${res.adj.tier}\`.`)
        }
        logChecks(t, [regular, ...extras], verdict, extras.some((x) => vclass(x.verdict) !== vclass(verdict)) ? (res.unresolved ? "unresolved" : "regular") : "agreement")
        return settle(t, att, verdict, !!a.fixable_local, false)
      }

      case "adjudicate": {
        const t = task!
        const att = t.attempts.at(-1)
        if (t.status !== "adjudicating" || !att?.adj) return finish(`REFUSED: ${t.id} is not waiting for an adjudication.`)
        const checks = att.checks ?? []
        const regular = checks.find((c) => c.role === "regular")!
        if (att.adj.kind === "reconcile") {
          const rv = a.reconcile_verdicts ?? []
          if (rv.length !== 2 || new Set(rv.map((v) => v.tier)).size !== 2 || rv.some((v) => !["sol", "astra"].includes(v.tier))) return finish("REFUSED: reconcile needs one verdict each from sol and astra.")
          if (vclass(rv[0].verdict) !== vclass(rv[1].verdict)) {
            logChecks(t, checks, regular.verdict!, "unresolved")
            log({ op: "verdict", id: t.id, unresolved: true, note: `sol and astra still disagree after reconciliation (${rv.map((x) => `${x.tier} ${x.verdict}`).join(", ")}); ask the user, then \`bench label\` and reset the task` })
            return finish(`${t.id} BLOCKED: sol and astra still disagree. Put it in STATUS.md as a question for the user; do not use the result in a claim until it is settled.`)
          }
          const final = rv.find((x) => x.tier === regular.tier)?.verdict ?? rv[0].verdict
          logChecks(t, checks, final, "reconcile", rv)
          return settle(t, att, final, !!att.adj.fixable, false)
        }
        if (!a.verdict || !a.checker_tier) return finish("ERROR: adjudicate needs the adjudicator's `verdict` and `checker_tier`.")
        if (a.checker_tier !== att.adj.tier || !a.checker_session || checks.some((c) => c.session === a.checker_session))
          return finish(`REFUSED: this ${att.adj.kind} needs a fresh ${att.adj.tier} adjudicator session.`)
        logChecks(t, [...checks, { tier: a.checker_tier as Tier, role: att.adj.kind === "audit" ? "audit" : "arbiter", verdict: a.verdict, session: a.checker_session } as any], a.verdict, att.adj.kind === "audit" ? "audit" : "arbiter")
        return settle(t, att, a.verdict, !!att.adj.fixable, false)
      }

      case "update": {
        const t = task!
        if (t.attempts.length && a.verify && a.verify !== t.verify) return finish("REFUSED: verification level is fixed after dispatch; add a new task for stronger verification.")
        if (a.priority === 1 && t.priority !== 1 && !a.note) return finish("REFUSED: raising priority to 1 needs a note.")
        if (a.status && a.status !== "pending" && !a.note) return finish(`REFUSED: ${a.status} needs a note.`)
        if (a.status === "pending" && !["failed", "blocked"].includes(t.status)) return finish("REFUSED: only failed or blocked tasks go back to pending.")
        log({ op: "update", id: t.id, status: a.status, priority: a.priority, verify: a.verify, difficulty: a.difficulty, note: a.note })
        return finish(`${t.id} updated.`)
      }

      case "gate": {
        if (!a.kind || !a.note) return finish("ERROR: gate needs `kind` and a `note` on the outcome.")
        if (a.kind === "redteam" && (task?.status !== "redteam" || !["pass", "fail"].includes(a.verdict)))
          return finish("REFUSED: redteam needs a task awaiting red-team review and an explicit pass/fail verdict.")
        if (["integration", "final"].includes(a.kind) &&
            !audit(L, cfg).must.some((m) => m.includes(`ledger gate kind=${a.kind}`)))
          return finish(`REFUSED: ${a.kind} is not due for this ledger revision.`)
        log({ op: "gate", kind: a.kind, id: a.id, verdict: a.verdict, note: a.note })
        appendText(workspacePath(dir, "research", "decisions.md"), `\n- ${now().slice(0, 16)} gate ${a.kind}: ${a.note}\n`)
        return finish(`Gate ${a.kind} recorded.`)
      }

      case "status": {
        const tasks = [...L.tasks.values()]
        const c = (s: string) => tasks.filter((t) => t.status === s).length
        const act = active(L)
        log({ op: "status", active: act, cap: cfg.concurrency })
        const al = bench ? usageAllowance(readJsonl(bench), cfg) : 0
        const compact = (text: string | undefined) => {
          const line = text?.replace(/\s+/g, " ").trim() ?? ""
          return line.length > 240 ? `${line.slice(0, 239)}…` : line
        }
        const current = tasks.filter((t) => ["running", "verifying", "adjudicating", "redteam"].includes(t.status))
          .sort((a, b) => a.priority - b.priority)
        const top = current.slice(0, 3).map((t) => `${t.id}: ${compact(t.title)} (${t.status === "redteam" ? "awaiting V4 red-team clearance" : t.status})`)
        const line = `ROUND ${L.rounds.length + 1} | done ${c("done")} / in flight ${current.length} / ready ${ready(L.tasks).length} / failed ${c("failed")} | slots ${act}/${cfg.concurrency}, probes ${probesActive(L)} | parallelism ${stats(L, cfg).parallelism.toFixed(1)} | allowance ${al ? al.toFixed(1) : "n/a"} | next: ${compact(a.next) || "-"}`
        const lines = [line]
        if (compact(a.focus)) lines.push(`- Focus: ${compact(a.focus)}`)
        const routes = (a.active_routes ?? []).map(compact).filter(Boolean)
        if (routes.length) lines.push(`- Routes: ${routes.slice(0, 3).join("; ")}${routes.length > 3 ? `; +${routes.length - 3} more (see route map or plan)` : ""}`)
        if (top.length) lines.push(`- In flight: ${top.join("; ")}${current.length > 3 ? `; +${current.length - 3} more (see ledger)` : ""}`)
        if (compact(a.changed)) lines.push(`- Changed: ${compact(a.changed)}`)
        if (compact(a.blockers)) lines.push(`- Waiting/blockers: ${compact(a.blockers)}`)
        const update = lines.join("\n")
        appendText(workspacePath(dir, "research", "STATUS.md"), update + "\n\n")
        return finish(update + (audit(L, cfg).must.length ? "\nDo the REQUIRED items before ending the round." : "\nNothing required: if workers are running, end your turn."))
      }

      case "stats": return finish(renderStats(stats(L, cfg), cfg))
      case "audit": { const au = audit(L, cfg); return finish(au.must.length || au.should.length ? "Audit:" : "Audit: clean.") }
      default: return finish(render(L))
    }
  },
})
