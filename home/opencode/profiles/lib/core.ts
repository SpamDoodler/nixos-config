// Shared logic for the `ledger` and `bench` tools and the profiles plugin: config, JSONL helpers,
// the model-tier benchmark (routing, reports) and the review benchmark.
// Lives in .opencode/lib/ (not tools/) so opencode does not register it as a tool.
import { appendFileSync, closeSync, constants, existsSync, fstatSync, ftruncateSync, lstatSync, mkdirSync, openSync, readFileSync, realpathSync, writeFileSync } from "node:fs"
import { basename, dirname, join } from "node:path"

/** Full escalation ladder. Only STARTABLE tiers can be a first attempt; astra is reached by escalation only. */
export const LADDER = ["luna", "terra-low", "terra", "sol-low", "sol", "astra", "astra-max"] as const
export type Tier = (typeof LADDER)[number]
export const tierVariants = {
  luna: ["luna", "medium"], "terra-low": ["terra", "low"], terra: ["terra", "medium"],
  "sol-low": ["sol", "low"], sol: ["sol", "high"], astra: ["astra", "xhigh"], "astra-max": ["astra", "max"],
} as const satisfies Record<Tier, readonly [string, string]>
export const STARTABLE: Tier[] = ["luna", "terra-low", "sol-low", "sol"]
export const MATCHED_PROBES = ["luna", "terra-low", "terra", "sol-low"] as const
export const TYPES = ["lookup", "literature", "derivation", "numerics", "code", "analysis", "explore", "other"]

// ---------- config ----------
export interface Config {
  cost: Record<Tier, number> // prior: relative allowance of one attempt (replaced by measurements once there are enough)
  latency: Record<Tier, number>
  verify_cost: number
  verify_latency: number
  rescope_cost: number
  time_weight: number
  weights: Record<Tier, number> // allowance weight per 1000 tokens of each tier (your subscription's relative quota price)
  cache_read_weight: number // cached input tokens count this much of a fresh token
  learned_cost_min_n: number // priced attempts per tier before measured cost replaces the prior
  prior_cap: Record<Tier, number>
  prior_strength: number
  explore_rate: number
  explore_min_n: number
  data_mode: "lean" | "balanced" | "max"
  shadow_rate: number // share of eligible tasks that get a probe one tier below the routed tier
  probe_luna: "most" | "uncertain" | "off" // luna worker probes: on most tasks, only where luna is uncertain, or never
  probe_slots: number // probes run in their own slots, so they never block main work
  check_down_rate: Record<"terra" | "sol", number> // a second check one model below the regular checker
  check_up_rate: Record<"terra" | "sol", number> // a second check one model above the regular checker
  astra_down_probe: "off" | "headline" | "p1" // sol re-checks astra's checks: never, on V4 claims, on all P1
  luna_audit_rate: number // share of luna-vs-terra disagreements re-judged by sol, to measure how often luna was right
  max_adjudications: number // per project; beyond it the regular verdict stands and the conflict is logged as unresolved
  concurrency: number
  astra_checks_p1_sol: boolean
  gate_every: number
  parallelism_target: number
}
export const DEFAULTS: Config = {
  cost: { luna: 1, "terra-low": 2, terra: 4, "sol-low": 7, sol: 15, astra: 60, "astra-max": 120 },
  latency: { luna: 2, "terra-low": 1.5, terra: 2.5, "sol-low": 2, sol: 4, astra: 6, "astra-max": 12 },
  verify_cost: 1,
  verify_latency: 1.5,
  rescope_cost: 30,
  time_weight: 1,
  weights: { luna: 0.05, "terra-low": 0.3, terra: 0.3, "sol-low": 1, sol: 1, astra: 3, "astra-max": 3 },
  cache_read_weight: 0.1,
  learned_cost_min_n: 5,
  prior_cap: { luna: 2, "terra-low": 2, terra: 3, "sol-low": 3, sol: 4, astra: 5, "astra-max": 5 },
  prior_strength: 2,
  explore_rate: 0.15,
  explore_min_n: 5,
  data_mode: "balanced",
  shadow_rate: 0.1,
  probe_luna: "most",
  probe_slots: 64,
  check_down_rate: { terra: 0.5, sol: 0.25 },
  check_up_rate: { terra: 0.05, sol: 0.03 },
  astra_down_probe: "headline",
  luna_audit_rate: 0.2,
  max_adjudications: 12,
  concurrency: 200,
  astra_checks_p1_sol: true,
  gate_every: 8,
  parallelism_target: 2.5,
}
const MODES: Record<string, Partial<Config>> = {
  lean: { explore_rate: 0, shadow_rate: 0, probe_luna: "off", check_down_rate: { terra: 0, sol: 0 }, check_up_rate: { terra: 0, sol: 0 }, astra_down_probe: "off", luna_audit_rate: 0 },
  balanced: {},
  max: { explore_rate: 0.3, shadow_rate: 0.25, check_down_rate: { terra: 0.8, sol: 0.5 }, check_up_rate: { terra: 0.1, sol: 0.06 }, astra_down_probe: "p1", luna_audit_rate: 0.3, max_adjudications: 25 },
}
export function loadConfig(): Config {
  const c = JSON.parse(readFileSync(new URL("../kit/tiers.json", import.meta.url), "utf8"))
  const mode = MODES[c.data_mode ?? DEFAULTS.data_mode] ?? MODES.balanced
  return {
    ...DEFAULTS, ...mode, ...c,
    cost: { ...DEFAULTS.cost, ...c.cost }, latency: { ...DEFAULTS.latency, ...c.latency },
    weights: { ...DEFAULTS.weights, ...c.weights }, prior_cap: { ...DEFAULTS.prior_cap, ...c.prior_cap },
    check_down_rate: { ...DEFAULTS.check_down_rate, ...mode.check_down_rate, ...c.check_down_rate },
    check_up_rate: { ...DEFAULTS.check_up_rate, ...mode.check_up_rate, ...c.check_up_rate },
    probe_luna: c.probe_luna === true ? "uncertain" : c.probe_luna === false ? "off" : (c.probe_luna ?? mode.probe_luna ?? DEFAULTS.probe_luna),
  }
}

// ---------- jsonl ----------
export function workspacePath(dir: string, ...parts: string[]) {
  let path = realpathSync(dir)
  for (const part of parts) {
    if (!/^[a-zA-Z0-9][a-zA-Z0-9._+-]*$/.test(part)) throw new Error("Invalid profile artifact path component")
    path = join(path, part)
    try {
      if (lstatSync(path).isSymbolicLink()) throw new Error("Profile artifact symlinks are not allowed")
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error
    }
  }
  return path
}
function regularFile<T>(path: string, flags: number, operation: (fd: number) => T): T {
  const fd = openSync(path, flags | constants.O_NOFOLLOW | constants.O_NONBLOCK, 0o600)
  try {
    const stat = fstatSync(fd)
    if (!stat.isFile() || stat.nlink !== 1 || stat.size > 16 * 1024 * 1024)
      throw new Error("Expected a regular, single-link profile file of at most 16 MiB")
    return operation(fd)
  } finally {
    closeSync(fd)
  }
}
export const readText = (p: string) => regularFile(p, constants.O_RDONLY, (fd) => readFileSync(fd, "utf8"))
export function readJsonl<T = any>(p: string): T[] {
  if (!existsSync(p)) return []
  const out: T[] = []
  for (const line of readText(p).split("\n")) {
    if (!line.trim()) continue
    try {
      out.push(JSON.parse(line))
    } catch {
      /* skip a corrupt line rather than lose the log */
    }
  }
  return out
}
export function appendJsonl(p: string, obj: unknown) {
  appendText(p, JSON.stringify(obj) + "\n")
}
export function appendText(p: string, text: string) {
  mkdirSync(dirname(p), { recursive: true })
  regularFile(p, constants.O_WRONLY | constants.O_CREAT | constants.O_APPEND, (fd) => appendFileSync(fd, text))
}
export function writeText(p: string, s: string) {
  mkdirSync(dirname(p), { recursive: true })
  regularFile(p, constants.O_WRONLY | constants.O_CREAT, (fd) => {
    writeFileSync(fd, s)
    ftruncateSync(fd, Buffer.byteLength(s))
  })
}
export const now = () => new Date().toISOString()
export const project = (dir: string) => basename(dir)
export const benchPath = (dir: string, modelSet: string) => workspacePath(dir, "research", "bench", `${modelSet}.jsonl`)
export const reviewBenchPath = (dir: string, modelSet: string) => workspacePath(dir, "review", "bench", `${modelSet}.jsonl`)
export const isReviewEvent = (e: any) => String(e.kind).startsWith("rv_") || e.type === "gap-resolution" || (e.kind === "usage" && String(e.agent).startsWith("rv-"))
export const ledgerPath = (dir: string) => workspacePath(dir, "research", "ledger.jsonl")
export const ledgerMdPath = (dir: string) => workspacePath(dir, "research", "LEDGER.md")

export type VerifyLevel = "V1" | "V2" | "V3" | "V4"

/** Time pressure: a failed attempt on a task many others wait on delays all of them. */
export function urgency(depth: number, priority: number) {
  return Math.min(4, 1 + 0.5 * (depth - 1)) * (priority === 1 ? 1.5 : 1)
}

// ---------- outcomes ----------
export type Verdict = "pass" | "pass_with_issues" | "fail" | "incomplete" | "wrong_question"
export type LabelSource = "human" | "replication" | "downstream" | "integration"
export interface Outcome {
  kind: "outcome"
  t: string
  project: string
  task_id: string
  title?: string
  type: string
  tags?: string[]
  difficulty: number
  difficulty_lo?: number
  difficulty_hi?: number
  priority?: number
  tier: Tier
  attempt: number
  verdict: Verdict
  verify_level?: VerifyLevel
  checker_tier?: string
  steps?: number
  seconds?: number
  note?: string
  shadow?: boolean // a probe: counterfactual attempt that never affects the task
  probe?: "luna" | "shadow" | "paired"
  route?: string // one of several distinct routes tried in parallel
  repaired?: boolean
  worker_session?: string
  checker_session?: string
  gate?: "pending" | "rejected" | "cleared"
  label?: "good" | "bad"
  labelSource?: LabelSource
  tokens?: number // effective tokens of the worker session (from the plugin)
  allowance?: number // tokens x tier weight / 1000
  allowance_check?: number
}
interface Usage { session: string; model?: string; tokens?: { input?: number; output?: number; reasoning?: number; cache?: { read?: number; write?: number } }; usd?: number }

export function effTokens(u: Usage, cfg: Config) {
  const t = u.tokens ?? {}
  return (t.input ?? 0) + (t.output ?? 0) + (t.reasoning ?? 0) + cfg.cache_read_weight * (t.cache?.read ?? 0)
}

export function loadOutcomes(path: string, cfg: Config = DEFAULTS, ledgerEvents: any[] = []): Outcome[] {
  const ev = readJsonl<any>(path)
  const outs: Outcome[] = ev.filter((e) => e.kind === "outcome" && !isReviewEvent(e))
  const attempts = new Map<string, number>(), gates = new Map<string, "cleared" | "rejected">()
  for (const event of ledgerEvents) {
    if (event.op === "dispatch") attempts.set(event.id, (attempts.get(event.id) ?? 0) + 1)
    if (event.op === "gate" && event.kind === "redteam" && attempts.has(event.id) && ["pass", "fail"].includes(event.verdict))
      gates.set(JSON.stringify([event.id, attempts.get(event.id)]), event.verdict === "pass" ? "cleared" : "rejected")
  }
  for (const o of outs) if (!o.shadow && o.verify_level === "V4" && verifierPassed(o))
    o.gate = gates.get(JSON.stringify([o.task_id, o.attempt])) ?? "pending"
  const usage = new Map<string, Usage>()
  for (const u of ev) if (u.kind === "usage" && u.session) usage.set(u.session, u) // latest wins: sessions are cumulative
  for (const o of outs) {
    const w = o.worker_session ? usage.get(o.worker_session) : undefined
    if (w) { o.tokens = effTokens(w, cfg); o.allowance = (o.tokens * cfg.weights[o.tier]) / 1000 }
    const c = o.checker_session ? usage.get(o.checker_session) : undefined
    if (c && o.checker_tier && o.checker_tier in cfg.weights) o.allowance_check = (effTokens(c, cfg) * cfg.weights[o.checker_tier as Tier]) / 1000
  }
  const rank: Record<LabelSource, number> = { integration: 1, downstream: 2, replication: 3, human: 4 }
  for (const l of ev.filter((e) => e.kind === "label"))
    for (const o of outs)
      if (o.project === l.project && o.task_id === l.task_id && (!l.tier || o.tier === l.tier)) {
        const src = (l.source ?? "human") as LabelSource
        if (!o.labelSource || rank[src] >= rank[o.labelSource]) { o.label = l.label; o.labelSource = src }
      }
  return outs
}

const verifierPassed = (o: Outcome) => o.verdict === "pass" || o.verdict === "pass_with_issues"
export function effective(o: Outcome): 1 | 0 | null {
  if (o.gate === "pending") return null
  if (o.gate === "rejected") return 0
  if (o.verdict === "wrong_question") return null
  if (o.label === "good") return 1
  if (o.label === "bad") return 0
  return verifierPassed(o) ? 1 : 0
}

// Learn from completed checks, not worker self-reports or missing evidence.
// A weaker worker's clean solve outweighs a stronger worker's failures.
export function difficultyEvidence(outs: Outcome[]) {
  if (outs.some((o) => o.tier === "luna" && o.verdict === "pass" && effective(o) === 1))
    return { delta: -1, reason: "Luna produced a clean, verified solve" }
  const failures = new Set(outs.filter((o) =>
    !o.shadow && !o.route && o.verdict === "fail" && effective(o) === 0 &&
    !outs.some((other) => other.tier === o.tier && effective(other) === 1)).map((o) => o.tier))
  if (failures.size >= 2)
    return { delta: 1, reason: `verified failures at ${[...failures].join(" and ")}` }
  if (outs.some((o) => effective(o) === 1)) return { delta: 0, reason: "verified solve at another tier" }
  return { delta: 0, reason: "not enough comparable evidence" }
}

export const shiftDifficulty = (grade: number, delta: number) => Math.min(5, Math.max(1, grade + delta))

export function calibrateDifficulty(outs: Outcome[], task: { id: string; difficulty: number; type: string; tags?: string[] }) {
  const groups = new Map<string, Outcome[]>()
  for (const o of outs) {
    if (o.task_id === task.id || o.difficulty !== task.difficulty || o.type !== task.type ||
        (task.tags?.length && !task.tags.some((tag) => o.tags?.includes(tag)))) continue
    const key = JSON.stringify([o.project, o.task_id])
    groups.set(key, [...(groups.get(key) ?? []), o])
  }
  const evidence = [...groups.values()].map(difficultyEvidence).filter((e) => e.reason !== "not enough comparable evidence")
  const down = evidence.filter((e) => e.delta < 0).length
  const up = evidence.filter((e) => e.delta > 0).length
  const direction = up >= 3 && up * 3 >= evidence.length * 2 ? 1 : down >= 3 && down * 3 >= evidence.length * 2 ? -1 : 0
  const grade = shiftDifficulty(task.difficulty, direction)
  return { grade, reason: grade === task.difficulty ? undefined :
    `workspace calibration: ${direction > 0 ? up : down}/${evidence.length} comparable tasks support ${direction > 0 ? "raising" : "lowering"} the starting grade` }
}

// ---------- routing ----------
function prior(tier: Tier, d: number, cfg: Config) {
  const cap = cfg.prior_cap[tier]
  return d <= cap ? 0.85 : d === cap + 1 ? 0.2 : 0.05
}

export function cell(outs: Outcome[], tier: Tier, type: string, d: number, cfg: Config) {
  let s = 0, f = 0, nExact = 0
  for (const o of outs) {
    if (o.tier !== tier) continue
    const e = effective(o)
    if (e === null) continue
    let w = 0
    if (o.type === type && o.difficulty === d) w = 1
    else if (o.difficulty === d) w = 0.4
    else if (o.type === type && Math.abs(o.difficulty - d) === 1) w = 0.25
    if (!w) continue
    if (w === 1) nExact++
    e ? (s += w) : (f += w)
  }
  const p0 = prior(tier, d, cfg)
  const a = cfg.prior_strength * p0 + s
  const b = cfg.prior_strength * (1 - p0) + f
  const p = a / (a + b)
  const sd = Math.sqrt((a * b) / ((a + b) ** 2 * (a + b + 1)))
  return { p, sd, lcb: Math.max(0, p - 0.84 * sd), nExact, nEff: s + f }
}

/** Replace each deployment's prior cost once it has enough priced attempts. */
export function withLearnedCost(cfg: Config, outs: Outcome[]): Config & { learned: boolean } {
  const mean = (t: Tier) => {
    const xs = outs.filter((o) => o.tier === t && typeof o.allowance === "number" && Number.isFinite(o.allowance) && o.allowance > 0).map((o) => o.allowance!)
    return xs.length >= cfg.learned_cost_min_n ? xs.reduce((a, b) => a + b, 0) / xs.length : null
  }
  const m = Object.fromEntries(LADDER.map((t) => [t, mean(t)])) as Record<Tier, number | null>
  const weighted = STARTABLE.filter((t) => m[t] !== null)
  if (!weighted.length) return { ...cfg, learned: false }
  const scale = m.sol !== null ? m.sol / cfg.cost.sol : weighted.reduce((sum, t) => sum + m[t]! / cfg.cost[t], 0) / weighted.length
  const checks = outs.filter((o) => typeof o.allowance_check === "number").map((o) => o.allowance_check!)
  return {
    ...cfg, learned: true,
    cost: Object.fromEntries(LADDER.map((t) => [t, m[t] ?? cfg.cost[t] * scale])) as Record<Tier, number>,
    verify_cost: checks.length >= cfg.learned_cost_min_n ? checks.reduce((a, b) => a + b, 0) / checks.length : cfg.verify_cost * scale,
    rescope_cost: cfg.rescope_cost * scale,
    time_weight: cfg.time_weight * scale,
  }
}

export interface RouteOpts { priority?: number; depth?: number; lowStakes?: boolean; rnd?: () => number }

/** E_i = c_i + v + w*(lat_i + lat_v) + (1 - p_i) * E_{i+1}; past sol: astra if priority 1, else a re-scope. */
export function route(outs: Outcome[], type: string, d: number, cfg0: Config, o: RouteOpts = {}) {
  const cfg = withLearnedCost(cfg0, outs)
  const priority = o.priority ?? 2
  const depth = o.depth ?? 1
  const w = cfg.time_weight * urgency(depth, priority)
  const ladder: Tier[] = priority === 1 ? [...STARTABLE, "astra"] : STARTABLE
  const cells = ladder.map((tier) => ({ tier, ...cell(outs, tier, type, d, cfg) }))
  const E: number[] = []
  for (let i = ladder.length - 1; i >= 0; i--) {
    const next = i === ladder.length - 1 ? cfg.rescope_cost : E[i + 1]
    E[i] = cfg.cost[ladder[i]] + cfg.verify_cost + w * (cfg.latency[ladder[i]] + cfg.verify_latency) + (1 - cells[i].p) * next
  }
  const minStart = d >= 5 ? STARTABLE.indexOf("sol") : d === 4 ? STARTABLE.indexOf("sol-low") : priority === 1 ? 1 : 0
  let best = minStart
  for (let i = minStart + 1; i < STARTABLE.length; i++) if (E[i] < E[best]) best = i
  let pick = best, explore = false
  const rnd = o.rnd ?? Math.random
  if (o.lowStakes && priority > 1 && depth <= 1 && best > minStart && cells[best - 1].nExact < cfg.explore_min_n && rnd() < cfg.explore_rate) { pick = best - 1; explore = true }
  const n = cells[best].nExact
  return {
    recommended: ladder[pick], explore, costBasis: cfg.learned ? "mixed measured allowance and priors" : "prior weights",
    evidence: n >= 10 ? "rich" : n >= 3 ? "ok" : "thin",
    luna: { p: cells[0].p, sd: cells[0].sd, n: cells[0].nExact },
    table: cells.map((c, i) => ({ tier: c.tier, p_pass: +c.p.toFixed(2), n_exact: c.nExact, expected_cost: +E[i].toFixed(2) })),
  }
}

export function usageAllowance(events: any[], cfg: Config) {
  const sessions = new Map<string, Usage>()
  // Older profiles recorded writer usage in the research log.
  for (const event of events) if (event.kind === "usage" && event.session && !String(event.agent).startsWith("w-")) sessions.set(event.session, event)
  let total = 0
  for (const usage of sessions.values()) {
    const [model, effort] = usage.model?.split("#") ?? []
    const tier = LADDER.find((tier) => model?.endsWith(`-${tierVariants[tier][0]}`) && effort === tierVariants[tier][1])
    if (tier) total += effTokens(usage, cfg) * cfg.weights[tier] / 1000
  }
  return total
}

// ---------- per-task results ----------
export function wilson(k: number, n: number, z = 1.96) {
  if (!n) return [0, 1]
  const p = k / n, d = 1 + (z * z) / n
  const c = (p + (z * z) / (2 * n)) / d, h = (z * Math.sqrt((p * (1 - p)) / n + (z * z) / (4 * n * n))) / d
  return [Math.max(0, c - h), Math.min(1, c + h)]
}

export interface TaskResult {
  key: string; title?: string; type: string; assigned: number; width: number; startTier: Tier
  minTier: Tier | null; firstPass: boolean; mainSolved: boolean; pending: boolean; escalations: number; wastedAllowance: number; wastedSeconds: number
}
export function taskResults(outs: Outcome[], cfg: Config = DEFAULTS): TaskResult[] {
  const by = new Map<string, Outcome[]>()
  for (const o of outs) by.set(`${o.project}/${o.task_id}`, [...(by.get(`${o.project}/${o.task_id}`) ?? []), o])
  const res: TaskResult[] = []
  for (const [key, list] of by) {
    list.sort((a, b) => a.attempt - b.attempt)
    const main = list.filter((o) => !o.shadow && !o.route)
    if (!main.length) continue
    const first = main[0]
    const solvedIdx = main.findIndex((o) => effective(o) === 1)
    const failedBefore = solvedIdx < 0 ? main : main.slice(0, solvedIdx)
    const solved = list.filter((o) => effective(o) === 1).map((o) => LADDER.indexOf(o.tier)) // probes and routes are real attempts too
    const base = {
      key, title: first.title, type: first.type, assigned: first.difficulty, startTier: first.tier,
      width: (first.difficulty_hi ?? first.difficulty) - (first.difficulty_lo ?? first.difficulty),
      firstPass: solvedIdx === 0 && first.attempt === 1 && !first.repaired,
      mainSolved: solvedIdx >= 0,
      pending: main.at(-1)?.gate === "pending",
      escalations: main.slice(1).filter((o, i) => LADDER.indexOf(o.tier) > LADDER.indexOf(main[i].tier)).length,
      wastedAllowance: failedBefore.filter((o) => effective(o) === 0).reduce((a, o) => a + (o.allowance ?? cfg.cost[o.tier]), 0),
      wastedSeconds: failedBefore.filter((o) => effective(o) === 0).reduce((a, o) => a + (o.seconds ?? 0), 0),
    }
    res.push({ ...base, minTier: solved.length ? LADDER[Math.min(...solved)] : null })
  }
  return res
}

const tok = (s: string) => new Set(s.toLowerCase().split(/[^a-z0-9]+/).filter((w) => w.length > 2))
export function similar(outs: Outcome[], query: string, type: string | undefined, k = 5) {
  const q = tok(query)
  return taskResults(outs)
    .filter((r) => r.title && (!type || r.type === type))
    .map((r) => { const t = tok(r.title!); const inter = [...q].filter((w) => t.has(w)).length; return { r, score: inter / Math.max(1, q.size + t.size - inter) } })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, k)
    .map(({ r, score }) => ({ title: r.title, type: r.type, assigned: r.assigned, started_at: r.startTier, lowest_observed_passing: r.minTier ?? "no observed pass", similarity: +score.toFixed(2) }))
}

const pct = (x: number) => (Number.isFinite(x) ? `${Math.round(x * 100)}%` : "-")
const avg = (xs: number[]) => (xs.length ? (xs.reduce((a, b) => a + b, 0) / xs.length).toFixed(1) : "-")
const frac = (xs: Outcome[]) => { const v = xs.filter((o) => effective(o) !== null); return v.length ? `${v.filter((o) => effective(o) === 1).length}/${v.length}` : "" }

export function toCSV(outs: Outcome[]): string {
  const cols = ["t", "project", "task_id", "title", "type", "tags", "difficulty", "difficulty_lo", "difficulty_hi", "priority", "tier", "attempt", "probe", "route", "repaired", "verdict", "verify_level", "checker_tier", "label", "labelSource", "seconds", "steps", "tokens", "allowance", "allowance_check"] as const
  const esc = (v: unknown) => { if (v === undefined || v === null) return ""; let s = Array.isArray(v) ? v.join(";") : String(v); if (typeof v !== "number" && /^[\s]*[=+@-]/.test(s)) s = "'" + s; return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s }
  return [cols.join(","), ...outs.map((o) => cols.map((c) => esc((o as any)[c])).join(","))].join("\n") + "\n"
}

// ---------- research benchmark report ----------
export function report(all: Outcome[], cfg: Config): string {
  const outs = all.filter((o) => o.type !== "gap-resolution") // review work is reported by reviewReport
  if (!outs.length) return "No outcomes logged yet."
  const tr = taskResults(outs, cfg)
  const L: string[] = [`# Benchmark report (${outs.length} attempts, ${tr.length} tasks)`, ""]
  const solved = tr.filter((r) => r.mainSolved)
  const hit = tr.filter((r) => r.firstPass)
  const unit = outs.some((o) => typeof o.allowance === "number") ? "allowance units (measured where available)" : "prior cost units"
  const spent = outs.reduce((a, o) => a + (o.allowance ?? cfg.cost[o.tier]), 0)
  const wasted = tr.reduce((a, r) => a + r.wastedAllowance, 0)
  L.push("## First-try allocation", "",
    `- Main worker passed on the first attempt without repair: ${hit.length}/${tr.length} (${pct(hit.length / Math.max(1, tr.length))}); probe successes do not count here.`,
    `- Escalated: ${tr.filter((r) => r.escalations > 0).length}. No cleared main solve: ${tr.length - solved.length} (including ${tr.filter((r) => r.pending).length} pending V4 gates).`,
    `- Spent on failed attempts: ${pct(wasted / Math.max(1e-9, spent))} of all ${unit}. Time lost to failed attempts: ${tr.reduce((a, r) => a + r.wastedSeconds, 0).toFixed(0)} s.`, "",
    "| started at | tasks | first-try pass | escalated | unsolved |", "| --- | --- | --- | --- | --- |")
  for (const t of STARTABLE) {
    const xs = tr.filter((r) => r.startTier === t)
    if (xs.length) L.push(`| ${t} | ${xs.length} | ${pct(xs.filter((r) => r.firstPass).length / xs.length)} | ${xs.filter((r) => r.escalations > 0).length} | ${xs.filter((r) => !r.mainSolved).length} |`)
  }

  // Which kinds of work suit which model: type x tier and tag x tier, all attempts (main, probes, routes).
  const tiersSeen = LADDER.filter((t) => outs.some((o) => o.tier === t))
  const matrix = (title: string, keys: string[], pick: (o: Outcome) => string[]) => {
    const rows = keys.filter((k) => outs.some((o) => pick(o).includes(k)))
    if (!rows.length) return
    L.push("", `## ${title} (verified passes / attempts)`, "", `| | ${tiersSeen.join(" | ")} |`, `| --- |${tiersSeen.map(() => " --- |").join("")}`)
    for (const k of rows) L.push(`| ${k} | ${tiersSeen.map((t) => frac(outs.filter((o) => o.tier === t && pick(o).includes(k)))).join(" | ")} |`)
  }
  matrix("By task type", [...new Set([...TYPES, ...outs.map((o) => o.type)])], (o) => [o.type])
  matrix("By tag", [...new Set(outs.flatMap((o) => o.tags ?? []))].sort(), (o) => o.tags ?? [])

  // Probes: the direct measurement of over-allocation.
  const probes = outs.filter((o) => o.shadow && effective(o) !== null)
  if (probes.length) {
    L.push("", "## Would a cheaper model have done? (probes)", "", "A probe is a blind attempt below the routed tier, checked like any other result; it never affects the task.", "",
      "| task routed to | probe tier | probes | probe also passed | 95% interval |", "| --- | --- | --- | --- | --- |")
    const mainTier = new Map<string, Tier>()
    for (const o of outs) if (!o.shadow && !o.route && o.attempt === 1) mainTier.set(`${o.project}/${o.task_id}`, o.tier)
    const groups = new Map<string, Outcome[]>()
    for (const o of probes) { const k = `${mainTier.get(`${o.project}/${o.task_id}`) ?? "?"}|${o.tier}`; groups.set(k, [...(groups.get(k) ?? []), o]) }
    for (const [k, xs] of [...groups.entries()].sort()) {
      const [m, p] = k.split("|"); const kk = xs.filter((o) => effective(o) === 1).length; const [lo, hi] = wilson(kk, xs.length)
      L.push(`| ${m} | ${p} | ${xs.length} | ${kk} (${pct(kk / xs.length)}) | ${pct(lo)}-${pct(hi)} |`)
    }
  }

  const paired = outs.filter((o) => o.probe === "paired" && effective(o) !== null)
  if (paired.length) {
    L.push("", "## Matched research calibration (Terra reference-graded)", "",
      "| task type | assigned difficulty | probe tier | passes / graded runs |", "| --- | --- | --- | --- |")
    const groups = new Map<string, Outcome[]>()
    for (const o of paired) {
      const key = JSON.stringify([o.type, o.difficulty, o.tier])
      groups.set(key, [...(groups.get(key) ?? []), o])
    }
    for (const [key, group] of groups) {
      const [type, difficulty, tier] = JSON.parse(key)
      L.push(`| ${type} | ${difficulty} | ${tier} | ${frac(group)} |`)
    }
  }

  // Multi-route exploration.
  const routes = outs.filter((o) => o.route && effective(o) !== null)
  if (routes.length) {
    const tasks = new Map<string, Outcome[]>()
    for (const o of routes) tasks.set(`${o.project}/${o.task_id}/${o.attempt}`, [...(tasks.get(`${o.project}/${o.task_id}/${o.attempt}`) ?? []), o])
    const any = [...tasks.values()].filter((xs) => xs.some((o) => effective(o) === 1)).length
    L.push("", "## Multi-route attempts", "", `${tasks.size} multi-route attempts, ${any} solved by at least one route. Per route: ${frac(routes)} passed.`, "",
      "| tier | routes | passed |", "| --- | --- | --- |", ...tiersSeen.filter((t) => routes.some((o) => o.tier === t)).map((t) => `| ${t} | ${routes.filter((o) => o.tier === t).length} | ${frac(routes.filter((o) => o.tier === t))} |`))
  }

  // Allowance.
  const priced = outs.filter((o) => typeof o.allowance === "number")
  if (priced.length) {
    L.push("", "## Allowance (from opencode session tokens x your tier weights)", "", "| tier | attempts priced | tokens per attempt | allowance per attempt | allowance per verified success | checking allowance per check |", "| --- | --- | --- | --- | --- | --- |")
    for (const t of LADDER) {
      const xs = priced.filter((o) => o.tier === t)
      if (!xs.length) continue
      const al = xs.reduce((a, o) => a + o.allowance!, 0), wins = xs.filter((o) => effective(o) === 1).length
      const ch = xs.filter((o) => typeof o.allowance_check === "number")
      L.push(`| ${t} | ${xs.length} | ${Math.round(xs.reduce((a, o) => a + (o.tokens ?? 0), 0) / xs.length)} | ${(al / xs.length).toFixed(2)} | ${wins ? (al / wins).toFixed(2) : "-"} | ${ch.length ? (ch.reduce((a, o) => a + o.allowance_check!, 0) / ch.length).toFixed(2) : "-"} |`)
    }
    const lc = withLearnedCost(cfg, outs)
    L.push("", lc.learned ? "`bench route` uses measured costs where there are enough samples and scaled priors elsewhere; dispatch is unchanged." : `\`bench route\` uses prior costs until a startable deployment has ${cfg.learned_cost_min_n} priced attempts; dispatch is unchanged.`)
  }

  // Pass rate by tier and difficulty.
  L.push("", "## Pass rate by tier and assigned difficulty", "", "| tier | diff | n | pass | avg sec |", "| --- | --- | --- | --- | --- |")
  for (const tier of LADDER)
    for (let d = 1; d <= 5; d++) {
      const xs = outs.filter((o) => o.tier === tier && o.difficulty === d && effective(o) !== null)
      if (xs.length) L.push(`| ${tier} | ${d} | ${xs.length} | ${pct(xs.filter((o) => effective(o) === 1).length / xs.length)} | ${avg(xs.map((o) => o.seconds ?? NaN).filter(Number.isFinite))} |`)
    }

  // Grading calibration, and whether the stated uncertainty means anything.
  L.push("", "## Grading calibration: lowest observed passing tier", "", "One cheaper failure does not prove a minimum tier.", "",
    `| assigned | ${LADDER.join(" | ")} | no observed pass |`, `| --- |${LADDER.map(() => " --- |").join("")} --- |`)
  for (let d = 1; d <= 5; d++) {
    const xs = tr.filter((r) => r.assigned === d)
    if (!xs.length) continue
    const c = (t: Tier) => xs.filter((r) => r.minTier === t).length
    L.push(`| ${d} | ${LADDER.map(c).join(" | ")} | ${xs.filter((r) => !r.minTier).length} |`)
  }
  const byWidth = [0, 1, 2].map((w) => tr.filter((r) => (w < 2 ? r.width === w : r.width >= 2)))
  if (byWidth[1].length || byWidth[2].length)
    L.push("", "Stated difficulty range vs what happened (a useful confidence signal escalates more often when the range is wide):", "",
      "| range width | tasks | escalated |", "| --- | --- | --- |", ...byWidth.map((xs, w) => `| ${w < 2 ? w : "2+"} | ${xs.length} | ${xs.length ? pct(xs.filter((r) => r.escalations > 0).length / xs.length) : "-"} |`))

  // Checker reliability.
  const labelled = outs.filter((o) => o.label && o.verdict !== "wrong_question")
  if (labelled.length) {
    L.push("", "## Checker reliability", "", "| evidence source | n | agree | checker passed, later found bad | checker failed, later found good |", "| --- | --- | --- | --- | --- |")
    for (const src of ["human", "replication", "downstream", "integration"] as LabelSource[]) {
      const xs = labelled.filter((o) => o.labelSource === src)
      if (xs.length) L.push(`| ${src} | ${xs.length} | ${pct(xs.filter((o) => (o.label === "good") === verifierPassed(o)).length / xs.length)} | ${xs.filter((o) => verifierPassed(o) && o.label === "bad").length} | ${xs.filter((o) => !verifierPassed(o) && o.label === "good").length} |`)
    }
  }
  const wq = outs.filter((o) => o.verdict === "wrong_question").length
  if (wq) L.push("", `${wq} attempts ended in WRONG_QUESTION; see the ledger notes.`)
  return L.join("\n")
}

// ---------- checker benchmark ----------
// kind "check": one checker's verdict on one result, with the final verdict after any adjudication.
// {project, task_id, type, difficulty, worker_tier, checker_tier, role: regular|down|up|audit|arbiter|reconcile,
//  verdict, final, resolved_by: agreement|regular|stronger|arbiter|audit|reconcile|unresolved}
const vclass = (v?: string) => (v === "pass" || v === "pass_with_issues" ? "pass" : v === "wrong_question" ? "wq" : v ? "fail" : "")
export function checkerReport(ev: any[]): string {
  const cs = ev.filter((e) => e.kind === "check")
  if (!cs.length) return ""
  const L = ["", "## Checkers (who judges well)", "",
    "Each result can get more than one check. The final verdict is the regular checker's, unless a disagreement was adjudicated. Agreement with the final verdict is only as good as that final verdict: read the adjudicated rows as the stronger evidence.", "",
    "| checker tier | role | checks | agrees with final | said pass, final fail | said fail, final pass | final settled by adjudication |", "| --- | --- | --- | --- | --- | --- | --- |"]
  const keys = [...new Set(cs.map((c) => `${c.checker_tier}|${c.role}`))].sort((a, b) => LADDER.indexOf(a.split("|")[0] as Tier) - LADDER.indexOf(b.split("|")[0] as Tier) || a.localeCompare(b))
  for (const k of keys) {
    const [t, r] = k.split("|")
    const xs = cs.filter((c) => c.checker_tier === t && c.role === r && c.final && c.resolved_by !== "unresolved")
    if (!xs.length) continue
    const ag = xs.filter((c) => vclass(c.verdict) === vclass(c.final)).length
    L.push(`| ${t} | ${r} | ${xs.length} | ${pct(ag / xs.length)} | ${xs.filter((c) => vclass(c.verdict) === "pass" && vclass(c.final) === "fail").length} | ${xs.filter((c) => vclass(c.verdict) === "fail" && vclass(c.final) === "pass").length} | ${xs.filter((c) => ["arbiter", "audit", "reconcile", "stronger"].includes(c.resolved_by)).length} |`)
  }
  const adj = cs.filter((c) => c.role === "regular" && ["stronger", "arbiter", "audit", "reconcile", "unresolved"].includes(c.resolved_by))
  if (adj.length) {
    L.push("", "Disagreements and how they ended:", "")
    for (const how of ["stronger", "audit", "arbiter", "reconcile", "unresolved"]) {
      const xs = adj.filter((c) => c.resolved_by === how)
      if (!xs.length) continue
      const regularRight = xs.filter((c) => vclass(c.verdict) === vclass(c.final)).length
      L.push(`- ${how}: ${xs.length}${how === "unresolved" ? " (regular verdict kept, not counted above)" : `; the regular checker was right in ${regularRight}`}`)
    }
  }
  const audits = cs.filter((c) => c.checker_tier === "luna" && c.resolved_by === "audit")
  if (audits.length) L.push("", `Luna disagreements audited by sol: luna was right in ${audits.filter((c) => vclass(c.verdict) === vclass(c.final)).length} of ${audits.length}. Unaudited luna disagreements are counted as luna wrong; this number says how much that biases luna's row.`)
  return L.join("\n")
}

// ---------- review benchmark ----------
// rv_check: one checker run {review, check_id, role, tier, claims[]}
// rv_finding: a candidate after triage {review, check_id, tier, role, claim, kind, severity, status: confirmed|downgraded|rejected|duplicate, origin?}
// rv_planted: a planted error, logged by the scorer after the review {review, planted_id, claim, kind, severity, trap?: boolean}
// rv_match: scorer's match of a planted error to a check {review, planted_id, check_id, found: boolean}
export function reviewReport(ev: any[]): string {
  const checks = ev.filter((e) => e.kind === "rv_check")
  const findings = new Map<string, any>()
  for (const e of ev.filter((e) => e.kind === "rv_finding")) {
    const key = JSON.stringify([e.review, e.check_id, e.finding_id])
    findings.set(key, { ...findings.get(key), ...e })
  }
  const finds = [...findings.values()]
  const planted = ev.filter((e) => e.kind === "rv_planted")
  const matches = ev.filter((e) => e.kind === "rv_match")
  const res = ev.filter((e) => e.kind === "outcome" && e.type === "gap-resolution")
  if (!checks.length && !res.length) return "No review data logged yet."
  const L: string[] = [`# Review benchmark (${new Set(checks.map((c) => c.review)).size} reviews, ${checks.length} checks)`]
  const checkKey = (c: any) => JSON.stringify([c.review, c.check_id])
  const key = (e: any) => `${e.role}@${e.tier}`
  const groups = [...new Set(checks.map(key))].sort()
  L.push("", "## Finding gaps", "", "Precision: share of a checker's candidates the lead confirmed (or downgraded but kept). Recall (relative): of confirmed findings on claims the checker examined, the share it raised. Recall (planted): of planted errors on claims it examined, the share it found.", "",
    "| role@tier | checks | candidates | precision | recall (relative) | recall (planted) | traps flagged |", "| --- | --- | --- | --- | --- | --- | --- |")
  const confirmed = finds.filter((f) => f.status === "confirmed" || f.status === "downgraded")
  for (const g of groups) {
    const cs = checks.filter((c) => key(c) === g)
    const ids = new Set(cs.map(checkKey))
    const mine = finds.filter((f) => ids.has(checkKey(f)))
    const good = mine.filter((f) => f.status === "confirmed" || f.status === "downgraded")
    // relative recall: confirmed findings (by anyone) on claims this group examined in the same review
    let seen = 0, raised = 0
    for (const c of cs) {
      const pool = confirmed.filter((f) => f.review === c.review && (c.claims ?? []).includes(f.claim))
      const claimsFound = new Set(pool.map((f) => f.claim))
      seen += claimsFound.size
      raised += [...claimsFound].filter((cl) => good.some((f) => checkKey(f) === checkKey(c) && f.claim === cl)).length
    }
    const pm = matches.filter((m) => ids.has(checkKey(m)) && planted.some((p) => p.review === m.review && p.planted_id === m.planted_id))
    const realPm = pm.filter((m) => !planted.find((p) => p.review === m.review && p.planted_id === m.planted_id)?.trap)
    const trapPm = pm.filter((m) => planted.find((p) => p.review === m.review && p.planted_id === m.planted_id)?.trap)
    L.push(`| ${g} | ${cs.length} | ${mine.length} | ${mine.length ? pct(good.length / mine.length) : "-"} | ${seen ? `${raised}/${seen}` : "-"} | ${realPm.length ? `${realPm.filter((m) => m.found).length}/${realPm.length}` : "-"} | ${trapPm.length ? `${trapPm.filter((m) => m.found).length}/${trapPm.length}` : "-"} |`)
  }
  const derive = checks.filter((c) => c.role === "derive" && c.task_id && c.difficulty && c.rigor)
  if (derive.length) {
    const grades = new Map(ev.filter((e) => e.kind === "rv_derive").map((e) => [checkKey(e), e.result]))
    L.push("", "## Blind re-derivation calibration", "",
      "| tier | difficulty | rigor | solved | incorrect | unresolved | ungraded | pending |",
      "| --- | --- | --- | --- | --- | --- | --- | --- |")
    for (const tier of LADDER) for (let d = 1; d <= 5; d++) for (const rigor of ["P", "M", "L"]) {
      const runs = derive.filter((c) => c.tier === tier && c.difficulty === d && c.rigor === rigor)
      if (!runs.length) continue
      const results = runs.map((c) => grades.get(checkKey(c)) ?? "pending")
      const counts = ["solved", "incorrect", "unresolved", "ungraded", "pending"].map((status) => results.filter((r) => r === status).length)
      L.push(`| ${tier} | ${d} | ${rigor} | ${counts.join(" | ")} |`)
    }
    const tasks = new Map<string, { review: string; task: string; tier?: Tier }>()
    for (const c of derive) {
      const id = JSON.stringify([c.review, c.task_id])
      const task = tasks.get(id) ?? { review: c.review, task: c.task_id }
      if (grades.get(checkKey(c)) === "solved" && (!task.tier || LADDER.indexOf(c.tier) < LADDER.indexOf(task.tier))) task.tier = c.tier
      tasks.set(id, task)
    }
    L.push("", "Lowest tier observed to solve each task (not a minimum capability guarantee):",
      ...[...tasks.values()].map((task) => {
        const runs = derive.filter((c) => c.review === task.review && c.task_id === task.task)
        const missing = [...MATCHED_PROBES, "sol"].filter((tier) => !runs.some((c) => c.tier === tier))
        return `- ${task.review}/${task.task}: ${task.tier ?? "no verified solve"}${missing.length ? `; missing runs: ${missing.join(", ")}` : ""}`
      }))
  }
  if (res.length) {
    L.push("", "## Resolving gaps independently", "", "| tier | attempts | resolved (verified one model up) |", "| --- | --- | --- |")
    for (const t of LADDER) { const xs = res.filter((o) => o.tier === t); if (xs.length) L.push(`| ${t} | ${xs.length} | ${xs.filter((o) => o.verdict === "pass" || o.verdict === "pass_with_issues").length}/${xs.length} |`) }
  }
  const origins = finds.filter((f) => f.origin && (f.status === "confirmed" || f.status === "downgraded"))
  if (origins.length) {
    L.push("", "## Where confirmed gaps came from", "")
    for (const o of ["WRITING", "RESEARCH", "CONFLICT", "UNTRACEABLE"]) { const n = origins.filter((f) => f.origin === o).length; if (n) L.push(`- ${o}: ${n}`) }
  }
  L.push("", "Traps are planted steps that are fine at physics-level rigor; flagging them is a false positive. Small samples: read the counts, not the percentages.")
  return L.join("\n")
}
