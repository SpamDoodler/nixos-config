import assert from "node:assert/strict"
import { appendFileSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import plugin, { latest } from "../home/opencode/profiles/index.ts"
import { loadConfig, route, taskResults } from "../home/opencode/profiles/lib/core.ts"
import { wantsProbes } from "../home/opencode/profiles/lib/ledger.ts"

const inventory = [
  ...["gpt-6-luna", "gpt-6.1-terra", "gpt-6.2-sol", "gpt-6.10-sol", "gpt-6.2-astra",
    "gpt-90-sol-fast", "gpt-70-sol-2026-11-18"].map((id) => ({ id, providerID: "openai" })),
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
  const messages = []
  let idle
  process.env.NIXSAMA_OPENCODE_RESEARCH = "1"
  process.env.OPENCODE_CONFIG_PROJECT_DISABLE = "1"
  await plugin.setup({
    model: { list: async () => ({ data: inventory }) },
    options: { tiers: { research: "sol", "r-worker-terra": "terra", write: "sol" } },
    location: { directory },
    agent: { transform: (apply) => apply({ update: (id, fn) => fn(agents[id] ??= {}) }) },
    tool: { transform: (apply) => apply({ add: (tool) => { tools[tool.name] = tool } }) },
    session: {
      hook: (_, callback) => { idle = callback },
      get: async ({ sessionID }) => sessionID === "worker" ? {
        id: sessionID, agent: "r-worker-terra", parentID: "main", tokens: { input: 1000, output: 10 },
      } : { id: sessionID, agent: "research" },
      synthetic: async (message) => messages.push(message),
    },
  })
  assert.equal(agents.research.model.id, "gpt-6.10-sol")
  assert.equal(agents["r-worker-terra"].model.id, "gpt-6.1-terra")
  assert.deepEqual(Object.keys(tools).sort(), ["bench", "ledger", "review_snapshot", "stylecheck"])
  const research = { agent: "research" }
  const writer = { agent: "write" }
  const task = { title: "Check units", type: "derivation", difficulty: 5, priority: 1, verify: "V4" }
  const ledger = async (input) => (await tools.ledger.execute(input, research)).content
  assert.notEqual(route([], "lookup", 1, loadConfig(), { priority: 1 }).recommended, "luna")
  const planned = { ...task, attempts: [], origDifficulty: 5, lo: 5, hi: 5 }
  const cfg = loadConfig()
  assert.equal(cfg.concurrency, 200)
  assert.equal(cfg.probe_slots, 64)
  const pick = (t, slots, overrides = {}) => wantsProbes(t, "sol", 1, { ...cfg, ...overrides }, { p: 0.1, n: 0 }, slots, () => 0.5)
  assert.deepEqual(pick(planned, 2, { data_mode: "lean" }).map((p) => p.tier), ["luna", "terra"])
  assert.deepEqual(pick(planned, 1), [])
  assert.deepEqual(pick({ ...planned, difficulty: 4, origDifficulty: 4 }, 2).map((p) => p.tier), ["luna", "terra"])
  const record = { project: "p", task_id: "1", type: "derivation", difficulty: 5 }
  const [count] = taskResults([
    { ...record, tier: "sol", attempt: 1, verdict: "pass", gate: "pending" },
    { ...record, tier: "luna", attempt: 0, shadow: true, verdict: "pass" },
  ])
  assert.equal(count.firstPass, false)
  assert.equal(count.pending, true)
  assert.equal(count.minTier, "luna")
  assert.match((await tools.ledger.execute({ action: "add", tasks: [task] }, writer)).content, /only available/)
  assert.match(await ledger({ action: "add", tasks: [{ ...task, id: "X", deps: ["X"] }] }), /dependency cycle/)
  assert.match(await ledger({ action: "add", tasks: [task, { ...task, deps: ["T001"] }] }), /T001, T002/)
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
  for (let i = 0; i < 3; i++) await idle({ sessionID: "main", background: [] })
  assert.equal(messages.length, 2)
  assert.match(messages[0].text, /r-redteam/)
  assert.match(await ledger({ action: "gate", kind: "redteam", id: "T001", verdict: "pass", note: "Checked" }), /done 1/)
  for (const tier of ["luna", "terra"]) {
    mkdirSync(join(folder, `probe-${tier}`), { recursive: true })
    writeFileSync(join(folder, `probe-${tier}/result.md`), "Units cancel")
    assert.match(await ledger({ action: "check", id: "T001", probe: tier }), /fresh r-verifier-t/)
    assert.match(await ledger({ action: "verdict", id: "T001", probe: tier, checker_tier: "terra", checker_session: `check-${tier}`, worker_session: `work-${tier}`, verdict: "pass" }), /Probe logged/)
  }
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
  const report = await bench({ action: "review_report" }, reviewer)
  assert.match(report, /\| luna \| 3 \| P \| 0 \| 0 \| 1 \| 0 \| 0 \|/)
  assert.match(report, /\| terra \| 3 \| P \| 1 \| 0 \| 0 \| 0 \| 0 \|/)
  assert.match(report, /\| sol \| 3 \| P \| 0 \| 0 \| 0 \| 0 \| 1 \|/)
  assert.match(report, /test\/D1: terra/)
  const lineup = "gpt-6-luna+gpt-6.1-terra+gpt-6.10-sol+gpt-6.2-astra"
  assert.match(readFileSync(join(directory, `review/bench/${lineup}.jsonl`), "utf8"), /rv_derive/)
  assert.doesNotMatch(readFileSync(join(directory, `research/bench/${lineup}.jsonl`), "utf8"), /rv_derive/)
  assert.match(await bench({ action: "dashboard" }, research), /2 graded.*0 missing/)
  const legacy = { kind: "rv_check", role: "lit", tier: "luna", review: "older", check_id: "L1", claims: ["C1"] }
  appendFileSync(join(directory, `research/bench/${lineup}.jsonl`), JSON.stringify(legacy) + "\n")
  const finding = { id: "F1", check_id: "L1", claim: "C1", status: "confirmed" }
  await bench({ action: "rv_findings", review: "older", items: [finding] }, reviewer)
  await bench({ action: "rv_findings", review: "older", items: [{ ...finding, status: "rejected" }] }, reviewer)
  assert.match(await bench({ action: "review_report" }, reviewer), /\| lit@luna \| 1 \| 1 \| 0% \|/)
  assert.match(readFileSync(join(directory, "research/bench/gpt-6-luna+gpt-6.1-terra+gpt-6.10-sol+gpt-6.2-astra.jsonl"), "utf8"), /T001/)
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
