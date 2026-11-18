import assert from "node:assert/strict"
import { appendFileSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import plugin, { latest } from "../home/opencode/profiles/index.ts"
import { calibrateDifficulty, difficultyEvidence, loadConfig, route, taskResults, usageAllowance, withLearnedCost } from "../home/opencode/profiles/lib/core.ts"
import { checkerPolicy, nextTier, tierGuard, wantsProbes } from "../home/opencode/profiles/lib/ledger.ts"

const inventory = [
  ...["gpt-6-luna", "gpt-6.1-terra", "gpt-6.2-sol", "gpt-6.10-sol", "gpt-6.2-astra",
    "gpt-90-sol-fast", "gpt-70-sol-2026-11-18"].map((id) => ({ id, providerID: "openai", variants: ["low", "max", "medium", "high", "xhigh"].map((id) => ({ id })) })),
  { id: "gpt-20-sol", providerID: "other" },
  { id: "gpt-30-sol", providerID: "openai", enabled: false },
]
assert.equal(latest(inventory, "sol"), "gpt-6.10-sol")

const directory = mkdtempSync(join(tmpdir(), "opencode-profile-test-"))
const random = Math.random
try {
  Math.random = () => 0.99
  process.env.NIXSAMA_OPENCODE_RESEARCH = "0"
  process.env.OPENCODE_CONFIG_PROJECT_DISABLE = "1"
  await plugin.setup({}) // No catalog access or tool registration outside the launcher.
  const agents = {}
  const tools = {}
  const builtinTools = {
    patch: { options: { codemode: false, permission: "edit" } },
    edit: { options: { codemode: false, permission: "edit" } },
    write: { options: { codemode: false, permission: "edit" } },
  }
  const messages = []
  let idle
  process.env.NIXSAMA_OPENCODE_RESEARCH = "1"
  process.env.OPENCODE_CONFIG_PROJECT_DISABLE = "1"
  await plugin.setup({
    model: { list: async () => ({ data: inventory }) },
    options: { tiers: { research: "sol", review: "sol", "rv-sanity": "terra-low", "r-worker-terra": "terra", "r-worker-luna": "luna", "r-worker-astra": "astra", "r-worker-terra-low": "terra-low", "r-worker-sol-low": "sol-low", "r-worker-astra-max": "astra-max", write: "sol", "w-drafter": "sol" } },
    location: { directory },
    agent: { transform: (apply) => apply({ update: (id, fn) => fn(agents[id] ??= { permissions: [] }) }) },
    tool: { transform: (apply) => apply({ update: (id, fn) => fn(builtinTools[id]), add: (tool) => { tools[tool.name] = tool } }) },
    session: {
      hook: (_, callback) => { idle = callback },
      get: async ({ sessionID }) => {
        const agent = { worker: "r-worker-terra", "writer-child": "w-drafter" }[sessionID]
        return agent ? { id: sessionID, agent, parentID: "main", tokens: { input: 1000, output: 10 } }
          : { id: sessionID, agent: sessionID === "writer" ? "write" : "research" }
      },
      synthetic: async (message) => messages.push(message),
    },
  })
  assert.equal(agents.research.model.id, "gpt-6.10-sol")
  assert.equal(agents["r-worker-terra"].model.id, "gpt-6.1-terra")
  assert.equal(agents.research.model.variant, "high")
  assert.equal(agents["r-worker-luna"].model.variant, "medium")
  assert.equal(agents["r-worker-terra"].model.variant, "medium")
  assert.equal(agents["r-worker-astra"].model.variant, "xhigh")
  assert.equal(agents["r-worker-terra-low"].model.variant, "low")
  assert.equal(agents["r-worker-sol-low"].model.variant, "low")
  assert.equal(agents["r-worker-astra-max"].model.variant, "max")
  assert.equal(agents.compaction.model.variant, "low")
  for (const name of ["research", "review", "r-worker-luna", "rv-sanity"])
    assert.deepEqual(agents[name].permissions.at(-1), { action: "patch", resource: "*", effect: "deny" })
  for (const name of ["write", "w-drafter"])
    assert.deepEqual(agents[name].permissions, [])
  assert.deepEqual(builtinTools.patch.options, { codemode: false, permission: "patch" })
  assert.equal(builtinTools.edit.options.permission, "edit")
  assert.equal(builtinTools.write.options.permission, "edit")
  assert.deepEqual(Object.keys(tools).sort(), ["bench", "ledger", "review_snapshot", "stylecheck"])
  const research = { agent: "research" }
  const writer = { agent: "write" }
  const task = { title: "Check units", type: "derivation", difficulty: 5, priority: 1, verify: "V4" }
  const ledger = async (input) => (await tools.ledger.execute(input, research)).content
  assert.notEqual(route([], "lookup", 1, loadConfig(), { priority: 1 }).recommended, "luna")
  const planned = { ...task, attempts: [], origDifficulty: 5, lo: 5, hi: 5 }
  const cfg = loadConfig()
  const usage = { kind: "usage", session: "test", model: "openai/gpt-6.10-sol#high", tokens: { input: 1000 } }
  assert.equal(usageAllowance([{ ...usage, agent: "w-drafter" }], cfg), 0)
  assert.equal(usageAllowance([{ ...usage, agent: "r-worker-sol" }], cfg), cfg.weights.sol)
  const priced = Array.from({ length: cfg.learned_cost_min_n }, () => ({ tier: "terra-low", allowance: 1.75 }))
  assert.equal(withLearnedCost(cfg, priced.slice(1)).learned, false)
  const measured = withLearnedCost(cfg, priced)
  assert.equal(measured.learned, true)
  assert.equal(measured.cost["terra-low"], 1.75)
  assert.equal(measured.cost.terra, cfg.cost.terra * 1.75 / cfg.cost["terra-low"])
  assert.equal(nextTier("luna"), "terra-low")
  assert.equal(nextTier("terra"), "sol-low")
  assert.equal(nextTier("astra"), null)
  assert.equal(checkerPolicy("terra-low", 2, cfg).tier, "sol-low")
  assert.equal(checkerPolicy("sol-low", 2, cfg).tier, "sol")
  assert.match(tierGuard({ id: "T", priority: 1, failedTiers: ["sol"] }, "astra-max"), /xhigh failure/)
  assert.equal(tierGuard({ id: "T", priority: 1, failedTiers: ["sol", "astra"] }, "astra-max"), null)
  assert.equal(route([], "derivation", 5, cfg, { priority: 1 }).recommended, "sol")
  assert.ok(!route([], "derivation", 5, cfg, { priority: 1 }).table.some((row) => ["astra-max", "terra"].includes(row.tier)))
  assert.equal(cfg.concurrency, 200)
  assert.equal(cfg.probe_slots, 64)
  const probeTiers = ["luna", "terra-low", "terra", "sol-low"]
  assert.deepEqual(wantsProbes(planned, 4).map((p) => p.tier), probeTiers)
  assert.deepEqual(wantsProbes(planned, 3), [])
  assert.deepEqual(wantsProbes({ ...planned, difficulty: 1, origDifficulty: 1 }, 4).map((p) => p.tier), probeTiers)
  const record = { project: "p", task_id: "1", type: "derivation", difficulty: 5 }
  const fail = (tier) => ({ ...record, tier, attempt: 1, verdict: "fail" })
  const lunaPass = { ...record, tier: "luna", verdict: "pass", shadow: true, attempt: 0, tags: ["symbolic"] }
  assert.equal(difficultyEvidence([fail("luna"), fail("luna")]).delta, 0)
  assert.equal(difficultyEvidence([fail("luna"), { ...fail("terra"), verdict: "incomplete" }]).delta, 0)
  assert.equal(difficultyEvidence([fail("luna"), fail("terra")]).delta, 1)
  assert.equal(difficultyEvidence([fail("luna"), fail("terra"), { ...lunaPass, gate: "pending" }]).delta, 1)
  assert.equal(difficultyEvidence([fail("luna"), fail("terra"), lunaPass]).delta, -1)
  assert.equal(difficultyEvidence([{ ...lunaPass, label: "bad" }]).delta, 0)
  const historical = ["a", "b", "c"].map((task_id) => ({ ...lunaPass, task_id }))
  const proposal = { id: "new", difficulty: 5, type: "derivation", tags: ["symbolic"] }
  assert.equal(calibrateDifficulty(historical.slice(0, 2), proposal).grade, 5)
  assert.equal(calibrateDifficulty(historical, proposal).grade, 4)
  assert.equal(calibrateDifficulty(historical, { ...proposal, tags: ["search"] }).grade, 5)
  const [count] = taskResults([
    { ...record, tier: "sol", attempt: 1, verdict: "pass", gate: "pending" },
    { ...record, tier: "luna", attempt: 0, shadow: true, verdict: "pass" },
  ])
  assert.equal(count.firstPass, false)
  assert.equal(count.pending, true)
  assert.equal(count.minTier, "luna")
  assert.match((await tools.ledger.execute({ action: "add", tasks: [task] }, writer)).content, /only available/)
  assert.match(await ledger({ action: "add", tasks: [{ ...task, id: "X", deps: ["X"] }] }), /dependency cycle/)
  const lineup = "gpt-6-luna.medium+gpt-6.1-terra.low+gpt-6.1-terra.medium+gpt-6.10-sol.low+gpt-6.10-sol.high+gpt-6.2-astra.xhigh+gpt-6.2-astra.max"
  const researchBench = join(directory, `research/bench/${lineup}.jsonl`)
  mkdirSync(join(directory, "research/bench"), { recursive: true })
  appendFileSync(researchBench, historical.map((o) => JSON.stringify({ ...o, kind: "outcome" })).join("\n") + "\n")
  assert.match(await ledger({ action: "add", tasks: [task, { ...task, deps: ["T001"] }] }), /T001, T002/)
  assert.match(await ledger({ action: "ready" }), /T001 P1 derivation d5 V4 -> sol/)
  assert.match(await ledger({ action: "dispatch", id: "T001" }), /pre-mortem/)
  const folder = join(directory, "research/tasks/T001")
  mkdirSync(join(folder, "replica"), { recursive: true })
  writeFileSync(join(folder, "card.md"), "Check units")
  await ledger({ action: "gate", kind: "premortem", note: "Reviewed" })
  assert.match(await ledger({ action: "dispatch", id: "T001", routes: 2 }), /cannot earn V3\/V4/)
  const dispatch = await ledger({ action: "dispatch", id: "T001" })
  assert.match(dispatch, /at sol/)
  assert.match(dispatch, /r-probe-luna/)
  assert.match(dispatch, /r-probe-terra/)
  assert.equal(readFileSync(join(folder, "probe-card.md"), "utf8"), "Check units")
  assert.match(await ledger({ action: "update", id: "T001", verify: "V1" }), /fixed after dispatch/)
  assert.match(await ledger({ action: "check", id: "T001" }), /result artifact/)
  writeFileSync(join(folder, "result.md"), "Units cancel")
  writeFileSync(join(folder, "replica/result.md"), "Units cancel")
  assert.match(await ledger({ action: "check", id: "T001" }), /r-verifier-a/)
  const verdict = { action: "verdict", id: "T001", checker_tier: "astra", checker_session: "checker", worker_session: "worker", verdict: "pass", check_verdicts: [{ tier: "sol", verdict: "pass", session: "cross-checker" }] }
  assert.match(await ledger(verdict), /awaits its red-team gate/)
  const progress = await ledger({
    action: "status", focus: "Check whether the units cancel",
    active_routes: ["R1: dimensional analysis", "R2: limiting case"],
    changed: "Both checkers passed", blockers: "Awaiting independent red-team verdict",
    next: "Record the gate verdict",
  })
  assert.match(progress, /Focus: Check whether the units cancel/)
  assert.match(progress, /Routes: R1: dimensional analysis; R2: limiting case/)
  assert.match(progress, /T001: Check units \(awaiting V4 red-team clearance\)/)
  assert.match(progress, /Waiting\/blockers: Awaiting independent red-team verdict/)
  assert.match(readFileSync(join(directory, "research/STATUS.md"), "utf8"), /Changed: Both checkers passed/)
  assert.match(await ledger({ action: "probe_finished", id: "T001", probe: "luna" }), /slot freed/)
  assert.match(await ledger({ action: "check", id: "T001", probe: "luna" }), /calibration needs a verified/)
  assert.match((await tools.bench.execute({ action: "dashboard" }, research)).content, /1 pending V4 gates/)
  assert.match(await ledger(verdict), /not awaiting a verdict/)
  assert.match(await ledger({ action: "dispatch", id: "T002" }), /waits on T001/)
  await idle({ sessionID: "worker", background: [] })
  const afterWorker = readFileSync(researchBench, "utf8")
  assert.ok(afterWorker.trim().split("\n").map((line) => JSON.parse(line)).some((e) => e.kind === "usage" && e.session === "worker"))
  for (const sessionID of ["writer", "writer-child"]) await idle({ sessionID, background: [] })
  assert.equal(readFileSync(researchBench, "utf8"), afterWorker)
  for (let i = 0; i < 3; i++) await idle({ sessionID: "main", background: [] })
  assert.equal(messages.length, 2)
  assert.match(messages[0].text, /r-redteam/)
  assert.match(await ledger({ action: "gate", kind: "redteam", id: "T001", verdict: "pass", note: "Checked" }), /done 1/)
  for (const tier of probeTiers) {
    mkdirSync(join(folder, `probe-${tier}`), { recursive: true })
    writeFileSync(join(folder, `probe-${tier}/result.md`), "Units cancel")
    assert.match(await ledger({ action: "check", id: "T001", probe: tier }), /fresh r-verifier-t/)
    const result = await ledger({ action: "verdict", id: "T001", probe: tier, checker_tier: "terra-low", checker_session: `check-${tier}`, worker_session: `work-${tier}`, verdict: "pass" })
    assert.match(result, /Probe logged/)
    assert.doesNotMatch(result, /Working difficulty/)
  }
  assert.match(readFileSync(join(directory, "research/LEDGER.md"), "utf8"), /\| T001 \| done \| P1 \| derivation \| 5 \(5\) \| V4 \|/)
  assert.match(await ledger({ action: "gate", kind: "integration", note: "Too early" }), /not due/)
  const reviewer = { agent: "review" }, scorer = { agent: "rv-scorer" }
  const paper = join(directory, "papers", "a paper")
  mkdirSync(join(paper, "figures"), { recursive: true })
  writeFileSync(join(paper, "main.tex"), "Original")
  writeFileSync(join(paper, ".env"), "Do not copy")
  const figure = Buffer.from([0, 255, 1, 2])
  writeFileSync(join(paper, "figures/plot.pdf"), figure)
  const snapshot = async (source, slug, agent = reviewer) =>
    (await tools.review_snapshot.execute({ source, slug }, agent)).content
  assert.match(await snapshot("papers/a paper", "test", writer), /only available/)
  assert.match(await snapshot("papers/a paper/.", "test"), /Snapshot ready.*2 files/)
  const target = join(directory, "review/test/target")
  assert.deepEqual(readFileSync(join(target, "figures/plot.pdf")), figure)
  assert.equal(existsSync(join(target, ".env")), false)
  assert.equal(readFileSync(join(target, "main.tex"), "utf8"), "Original")
  writeFileSync(join(paper, "main.tex"), "New version")
  assert.match(await snapshot("papers/a paper", "test"), /already exists/)
  assert.equal(readFileSync(join(target, "main.tex"), "utf8"), "Original")
  assert.match(await snapshot("papers/a paper/main.tex", "single", { agent: "rv-planter" }), /Snapshot ready/)
  assert.match(await snapshot("../escape", "bad"), /refused/)
  assert.match(await snapshot("papers/a paper", "../bad"), /Invalid review slug/)
  symlinkSync(join(paper, "main.tex"), join(paper, "linked.tex"))
  assert.match(await snapshot("papers/a paper", "linked"), /symlink/)
  assert.equal(existsSync(join(directory, "review/linked/target")), false)
  symlinkSync(paper, join(directory, "review/redirect"))
  assert.match(await snapshot("papers/a paper/main.tex", "redirect"), /symlink/)
  assert.equal(existsSync(join(paper, "target")), false)
  const bench = async (input, agent) => (await tools.bench.execute(input, agent)).content
  await bench({ action: "rv_check", review: "test", check_id: "S1", role: "sanity", tier: "terra", claims: ["C1"] }, reviewer)
  assert.match(await bench({ action: "rv_planted", review: "test", items: [{ id: "P1" }] }, reviewer), /not available/)
  await bench({ action: "rv_planted", review: "test", items: [{ id: "P1", kind: "WRONG", claim: "C1" }] }, scorer)
  await bench({ action: "rv_matches", review: "test", items: [{ id: "P1", check_id: "S1", found: true }] }, scorer)
  assert.match(await bench({ action: "review_report" }, reviewer), /sanity@terra.*1\/1/)
  const derive = { action: "rv_check", review: "test", role: "derive", task_id: "D1", difficulty: 3, rigor: "P", claims: ["C1"] }
  for (const tier of ["luna", "terra", "sol"])
    assert.match(await bench({ ...derive, check_id: `D1-${tier}`, tier }, reviewer), /logged/)
  assert.match(await bench({ ...derive, check_id: "D1-replica", tier: "sol", difficulty: 4 }, reviewer), /same pre-run/)
  assert.match(await bench({ ...derive, check_id: "D1-luna", tier: "luna" }, reviewer), /already registered/)
  const score = (check_id, derive_result) => bench({ action: "rv_derive", review: "test", check_id, derive_result }, reviewer)
  assert.match(await score("missing", "solved"), /register/)
  await score("D1-luna", "unresolved")
  await score("D1-terra", "incorrect")
  await score("D1-terra", "solved") // A corrected adjudication counts once.
  assert.match(await bench({ ...derive, task_id: "D2", check_id: "D2-sol", rigor: "L", tier: "sol" }, reviewer), /logged/)
  assert.match(await score("D2-sol", "solved"), /certificate evidence/)
  assert.match(await bench({ action: "rv_derive", review: "test", check_id: "D2-sol", derive_result: "solved", note: "review/test/checks/D2-sol-certificate.md" }, reviewer), /solved/)
  const report = await bench({ action: "review_report" }, reviewer)
  assert.match(report, /\| luna \| 3 \| P \| 0 \| 0 \| 1 \| 0 \| 0 \|/)
  assert.match(report, /\| terra \| 3 \| P \| 1 \| 0 \| 0 \| 0 \| 0 \|/)
  assert.match(report, /\| sol \| 3 \| P \| 0 \| 0 \| 0 \| 0 \| 1 \|/)
  assert.match(report, /test\/D1: terra/)
  assert.match(report, /\| sol \| 3 \| L \| 1 \| 0 \| 0 \| 0 \| 0 \|/)
  assert.match(readFileSync(join(directory, `review/bench/${lineup}.jsonl`), "utf8"), /rv_derive/)
  assert.doesNotMatch(readFileSync(join(directory, `research/bench/${lineup}.jsonl`), "utf8"), /rv_derive/)
  assert.match(await bench({ action: "dashboard" }, research), /4 graded.*0 missing/)
  const legacy = { kind: "rv_check", role: "lit", tier: "luna", review: "older", check_id: "L1", claims: ["C1"] }
  appendFileSync(join(directory, `research/bench/${lineup}.jsonl`), JSON.stringify(legacy) + "\n")
  const finding = { id: "F1", check_id: "L1", claim: "C1", status: "confirmed" }
  await bench({ action: "rv_findings", review: "older", items: [finding] }, reviewer)
  await bench({ action: "rv_findings", review: "older", items: [{ ...finding, status: "rejected" }] }, reviewer)
  assert.match(await bench({ action: "review_report" }, reviewer), /\| lit@luna \| 1 \| 1 \| 0% \|/)
  assert.match(readFileSync(join(directory, `research/bench/${lineup}.jsonl`), "utf8"), /T001/)
  mkdirSync(join(directory, "writing/test"), { recursive: true })
  writeFileSync(join(directory, "writing/test/draft.md"), "The units cancel.\n")
  await tools.stylecheck.execute({ path: "writing/test/draft.md", genre: "report", slug: "test" }, writer)
  assert.match(readFileSync(join(directory, "writing/test/lint-history.jsonl"), "utf8"), /writing\/test\/draft.md/)
  symlinkSync("draft.md", join(directory, "writing/test/link.md"))
  await assert.rejects(tools.stylecheck.execute({ path: "writing/test/link.md", genre: "report" }, writer), /symlink/)
  assert.match((await tools.stylecheck.execute({ path: "writing/test/draft.md", genre: "report", slug: ".." }, writer)).content, /matching slug/)
  console.log("PASS: model selection, tool authorization, ledger escalation, benchmarks, and stylecheck")
} finally {
  Math.random = random
  rmSync(directory, { recursive: true, force: true })
}
