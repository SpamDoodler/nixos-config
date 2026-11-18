import { tool } from "../lib/tool.ts"
import { appendJsonl, benchPath, checkerReport, isReviewEvent, ledgerPath, loadConfig, loadOutcomes, now, project, readJsonl, report, reviewBenchPath, reviewReport, route, similar, toCSV, workspacePath, writeText } from "../lib/core.ts"
import { fold } from "../lib/ledger.ts"

const TIERS = ["luna", "terra", "sol", "astra"] as const

export default tool({
  description:
    "Workspace model benchmark, partitioned by model lineup. Research outcomes are logged by `ledger verdict`; use this for: report, review_report, similar, route, export (CSV), label (later evidence about a result), " +
    "outcome (work outside the ledger, e.g. type gap-resolution in reviews), and review events rv_check, rv_derive, rv_findings, rv_planted, rv_matches.",
  args: {
    action: tool.schema.enum(["dashboard", "report", "review_report", "similar", "route", "export", "label", "outcome", "rv_check", "rv_derive", "rv_findings", "rv_planted", "rv_matches"]),
    review: tool.schema.string().optional().describe("review slug, for rv_* events"),
    task_id: tool.schema.string().optional(),
    title: tool.schema.string().optional().describe("task title, or query for `similar`"),
    type: tool.schema.string().optional(),
    tags: tool.schema.array(tool.schema.string()).optional(),
    difficulty: tool.schema.number().int().min(1).max(5).optional(),
    priority: tool.schema.number().int().min(1).max(3).optional(),
    depth: tool.schema.number().int().min(1).optional(),
    tier: tool.schema.enum(TIERS).optional(),
    attempt: tool.schema.number().int().min(0).optional(),
    verdict: tool.schema.enum(["pass", "pass_with_issues", "fail", "incomplete", "wrong_question"]).optional(),
    checker_tier: tool.schema.enum(TIERS).optional(),
    worker_session: tool.schema.string().optional(),
    checker_session: tool.schema.string().optional(),
    label: tool.schema.enum(["good", "bad"]).optional(),
    source: tool.schema.enum(["human", "replication", "downstream", "integration"]).optional(),
    check_id: tool.schema.string().optional().describe("rv_check: id of one checker run, e.g. S3"),
    role: tool.schema.string().optional().describe("rv_check: mapper|derive|sanity|lit|consistency|trace|resolve"),
    claims: tool.schema.array(tool.schema.string()).optional().describe("rv_check: claim ids the check examined"),
    rigor: tool.schema.enum(["P", "M"]).optional().describe("Matched blind derive runs: target rigor"),
    derive_result: tool.schema.enum(["solved", "incorrect", "unresolved", "ungraded"]).optional(),
    items: tool.schema.array(tool.schema.object({
      id: tool.schema.string().describe("finding id or planted id"),
      check_id: tool.schema.string().optional(),
      tier: tool.schema.enum(TIERS).optional(),
      role: tool.schema.string().optional(),
      claim: tool.schema.string().optional(),
      kind: tool.schema.string().optional(),
      severity: tool.schema.string().optional(),
      status: tool.schema.enum(["confirmed", "downgraded", "rejected", "duplicate"]).optional().describe("rv_findings: fate after triage"),
      origin: tool.schema.enum(["WRITING", "RESEARCH", "CONFLICT", "UNTRACEABLE"]).optional(),
      trap: tool.schema.boolean().optional().describe("rv_planted: a step that is fine at physics level"),
      found: tool.schema.boolean().optional().describe("rv_matches: did this check find this planted item"),
    })).optional(),
    note: tool.schema.string().optional(),
  },
  async execute(a, ctx) {
    const dir = ctx.directory
    if (!ctx.modelSet) return "ERROR: all four OpenAI model families must be available to benchmark."
    const researchPath = benchPath(dir, ctx.modelSet)
    const reviewPath = reviewBenchPath(dir, ctx.modelSet)
    const reviewEvents = () => [...readJsonl(researchPath).filter(isReviewEvent), ...readJsonl(reviewPath)]
    const path = a.action.startsWith("rv_") || a.type === "gap-resolution" ? reviewPath : researchPath
    const cfg = loadConfig()
    const reviewActions = ["dashboard", "rv_check", "rv_derive", "rv_findings", "review_report"]
    if ((ctx.agent === "rv-scorer" && !["rv_planted", "rv_matches"].includes(a.action)) ||
        (ctx.agent === "review" && !reviewActions.includes(a.action) && !(a.action === "outcome" && a.type === "gap-resolution")) ||
        (ctx.agent === "research" && (a.action.startsWith("rv_") || a.type === "gap-resolution")))
      return "ERROR: action is not available to this agent."
    const t = now(), proj = project(dir)
    const needReview = () => (!a.review ? "ERROR: rv_* actions need `review`." : null)
    switch (a.action) {
      case "outcome":
        for (const k of ["task_id", "type", "difficulty", "tier", "verdict"] as const) if (a[k] === undefined) return `ERROR: outcome needs ${k}.`
        appendJsonl(path, { kind: "outcome", t, project: proj, task_id: a.task_id, title: a.title, type: a.type, tags: a.tags, difficulty: a.difficulty, priority: a.priority, tier: a.tier, attempt: a.attempt ?? 1, verdict: a.verdict, checker_tier: a.checker_tier, worker_session: a.worker_session, checker_session: a.checker_session, note: a.note })
        return `Logged ${a.task_id} ${a.type} ${a.tier}: ${a.verdict}.`
      case "label":
        if (!a.task_id || !a.label) return "ERROR: label needs task_id and label."
        appendJsonl(path, { kind: "label", t, project: proj, task_id: a.task_id, tier: a.tier, label: a.label, source: a.source ?? "human" })
        return `Labelled ${a.task_id} ${a.label}.`
      case "rv_check": {
        const e = needReview(); if (e) return e
        if (!a.check_id || !a.role || !a.tier) return "ERROR: rv_check needs check_id, role, tier."
        const checks = reviewEvents().filter((ev) => ev.kind === "rv_check" && ev.review === a.review)
        if (checks.some((ev) => ev.check_id === a.check_id)) return "ERROR: check ID already registered for this review."
        if (a.role === "derive" && (a.task_id || a.difficulty || a.rigor)) {
          if (!a.task_id || !a.difficulty || !a.rigor) return "ERROR: matched derive runs need task_id, difficulty and rigor."
          const prior = checks.find((ev) => ev.role === "derive" && ev.task_id === a.task_id)
          if (prior && (prior.difficulty !== a.difficulty || prior.rigor !== a.rigor))
            return "ERROR: matched runs must use the same pre-run difficulty and rigor."
        }
        appendJsonl(path, { kind: "rv_check", t, review: a.review, check_id: a.check_id, role: a.role, tier: a.tier, claims: a.claims ?? [],
          task_id: a.role === "derive" ? a.task_id : undefined, difficulty: a.role === "derive" ? a.difficulty : undefined, rigor: a.role === "derive" ? a.rigor : undefined })
        return `Check ${a.check_id} (${a.role}@${a.tier}) logged.`
      }
      case "rv_derive": {
        const e = needReview(); if (e) return e
        if (!a.check_id || !a.derive_result) return "ERROR: rv_derive needs check_id and derive_result."
        const check = reviewEvents().find((ev) => ev.kind === "rv_check" && ev.review === a.review && ev.check_id === a.check_id)
        if (check?.role !== "derive" || !check.task_id || !check.difficulty || !check.rigor)
          return "ERROR: register a matched derive run before recording its result."
        appendJsonl(path, { kind: "rv_derive", t, review: a.review, check_id: a.check_id, result: a.derive_result, note: a.note })
        return `Blind derivation ${a.check_id}: ${a.derive_result}.`
      }
      case "rv_findings": case "rv_planted": case "rv_matches": {
        const e = needReview(); if (e) return e
        if (!a.items?.length) return "ERROR: needs `items`."
        const kind = a.action === "rv_findings" ? "rv_finding" : a.action === "rv_planted" ? "rv_planted" : "rv_match"
        for (const it of a.items) appendJsonl(path, { ...it, kind, item_kind: it.kind, t, review: a.review, ...(kind === "rv_finding" ? { finding_id: it.id } : { planted_id: it.id }) })
        return `Logged ${a.items.length} ${kind} event(s).`
      }
      case "review_report":
        return reviewReport(reviewEvents())
    }
    const events = readJsonl(ledgerPath(dir))
    const outs = loadOutcomes(researchPath, cfg, events)
    const coverage = () => {
      const tasks = [...fold(events).tasks.values()].filter((t) => t.attempts.length && (t.origDifficulty === 5 || t.difficulty === 5))
      const rows = tasks.flatMap((t) => ["luna", "terra"].map((tier) => {
        const p = t.probes.find((p) => p.tier === tier)
        const status = !p ? "missing" : p.done ? p.result === "ungraded" ? "ungraded" : "graded" : p.workerFinished ? "awaiting grade" : "dispatched"
        return { id: t.id, tier, status }
      }))
      const summary = ["graded", "ungraded", "awaiting grade", "dispatched", "missing"].map((s) => `${rows.filter((r) => r.status === s).length} ${s}`)
      return `## Difficulty-5 paired probe coverage\n${tasks.length} tasks: ${summary.join(", ")}.\n` +
        rows.filter((r) => r.status !== "graded").map((r) => `- ${r.id}/${r.tier}: ${r.status}`).join("\n")
    }
    if (a.action === "dashboard")
      return `${coverage()}\n\n${report(outs, cfg)}\n\n${reviewReport(reviewEvents())}`
    if (a.action === "route") {
      if (!a.type || !a.difficulty) return "ERROR: route needs type and difficulty."
      return JSON.stringify(route(outs, a.type, a.difficulty, cfg, { priority: a.priority, depth: a.depth }), null, 1)
    }
    if (a.action === "similar") {
      if (!a.title) return "ERROR: similar needs `title`."
      const r = similar(outs, a.title, a.type)
      return r.length ? JSON.stringify(r, null, 1) : "No similar past tasks yet."
    }
    if (a.action === "export") {
      writeText(workspacePath(dir, "research", "bench-export.csv"), toCSV(outs))
      return `Wrote ${outs.length} attempts to research/bench-export.csv.`
    }
    return `${coverage()}\n\n${report(outs, cfg)}${checkerReport(readJsonl(researchPath))}`
  },
})
