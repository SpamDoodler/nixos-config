# Making OpenCode more token-efficient and faster

Research and local verification: 9 October 2026.

## Executive recommendation

Start with **one agent, the same model and effort as the Codex comparison, the native provider integration, a small project instruction file, selective tool output, and an explicit stopping condition**. Measure that baseline before restoring plugins, multiple agents, or elaborate research governance. For routine work, then test lower reasoning effort. For difficult mathematical work, preserve reasoning and remove orchestration overhead first.

This is an evidence-backed optimization strategy, **not a demonstrated claim that OpenCode now matches Codex**. No authenticated Codex/OpenCode head-to-head run was possible here: neither executable nor an `OPENAI_API_KEY` was available, and your actual configuration and session exports were not supplied. Local implementation inspection and mechanism tests were performed; a reproducible benchmark protocol follows.

“Codex” can mean its model, CLI, or hosted ChatGPT Work environment. Those are different comparisons. A local OpenCode versus Codex CLI experiment can isolate much of the agent harness; a local OpenCode versus hosted Work comparison also includes different machines, tools, network routes, and potentially model serving settings.

## 1. What probably causes the difference

A useful accounting identity is:

```text
Task time = startup + critical path of model calls and tool execution
            + retries/backoff + approval/idle waits

Model-call time = network/queue time + input processing
                  + reasoning/output generation
```

Parallel work overlaps, so do not sum every span and call the result wall time. Optimize time to a **correct, verified result**, not time to first displayed text.

| Candidate cause | Evidence and confidence | Diagnostic | Intervention |
|---|---|---|---|
| Different actual model or effort | Strong confounder; not measured in your setup | Record resolved model, provider, variant and outgoing effort | Match these before attributing anything to the harness |
| Too many serial model turns | Documented general latency mechanism [1] | Count model requests and classify each turn | Batch independent reads, remove routine planning/review handoffs |
| Excess reasoning on easy tasks | Reasoning is separately configurable [2, 3] | Compare low/medium on identical tasks and validators | Route by difficulty; retain high effort where it improves success |
| Repeated large tool results | Context grows and gets replayed; local payload test below | Record tool-output bytes and per-request input usage | Return relevant excerpts and persist full raw results |
| Cache disruption | Provider requires a matching rendered prefix [4] | Compare cache reads across successive requests | Stable instructions/tools; avoid unnecessary mid-session changes |
| Provider adapter differences | Native OpenAI and generic compatible paths differ in retrieved source [5] | Check endpoint, serialized options and reasoning-item replay | Prefer native integration; audit gateways before adding patches |
| Startup/plugin/MCP overhead | OpenCode documents attached server operation to avoid MCP cold starts [6] | Compare fresh process versus attached process | Keep the backend warm only if startup is material |
| Proxy, retries, serving tier | Plausible, especially for geographically different clients; not measured here | Timestamp request, first event, last event, retries and tools | Match routes/tier when possible; isolate network stalls |
| Rework caused by vague goals | Engineering hypothesis | Count clarification and correction turns | Specify deliverable, invariant, scope and stopping test |

OpenAI’s latency guide emphasizes generation and request count; it cautions that halving input may yield only a small latency improvement for ordinary prompts [1]. Thus, reducing prompt length can save tokens without producing a proportional time improvement.

### Important corrections to common explanations

The files retrieved from OpenCode's `v1.18.35` source URL contain:

- A native `openai` provider returning `sdk.responses(modelID)`.
- A provider transform assigning `promptCacheKey` from the session ID for supported integrations unless disabled.
- Model-specific GPT/Codex/Astra prompt selection.
- Handling of `reasoning.encrypted_content` in provider options.

These are source observations, not a runtime trace. They refute “OpenCode always uses Chat Completions,” “OpenCode has no model-specific prompts,” and “OpenCode never sets a cache key” as general explanations. They do **not** prove your installed provider/plugin path preserves all options or actually receives cache hits. [5]

Do not install an old cache/auth workaround merely because a historical report recommends it. First reproduce the defect on your pinned version. The official changelog records provider SDK updates, reasoning compatibility fixes, and transport-related changes; implementation age matters [7].

There is no evidence from this investigation for a universal, measured Codex/OpenCode performance ratio or for attributing your entire gap to secret prompting. Model quality, harness behavior and infrastructure remain separable hypotheses.

## 2. Measure the right token quantities

Record per request and aggregate per completed task:

| Quantity | Why it matters |
|---|---|
| Total input tokens | Measures context traffic, including repeated history |
| Cached input / cache-read tokens | Measures reuse; does not mean the tokens vanished |
| Cache-write tokens, when exposed | Needed for model-specific cost accounting |
| Output tokens | Usually includes reasoning in OpenAI accounting; check the actual schema |
| Reasoning tokens, when exposed | Explains long hidden generation; normally a subset, not an extra amount to add |
| Model requests and tool calls | Explains orchestration overhead |
| End-to-end time and success | Prevents rewarding quick but wrong answers |
| Retry, compaction and child-agent usage | Prevents excluding expensive background work |

Do not add reasoning tokens twice. Do not assume OpenCode's normalized `input` field has identical semantics to OpenAI's raw `input_tokens`: check the pinned exporter and provider adapter. Preserve raw usage alongside normalized totals. Mark unavailable fields as **unknown**, never zero.

Report both raw input+output and provider-billed cost if available. Cache reuse can reduce processing/cost without reducing raw logical input. Subscription quota accounting is not established by an API-token measurement.

For repeated work, use `total tokens spent across all attempts / successful tasks`, alongside first-attempt success. A cheap weak model that requires repeated rescue can lose both objectives.

## 3. Implementation order

### Step 1 — Freeze and inventory the real setup

Use a disposable project copy and preserve your working configuration. Record:

```bash
opencode --version
opencode models openai
opencode run --help
codex --version
codex exec --help
```

Also record the model ID, auth route (API or subscription), provider endpoint category, selected variant, plugins, active MCP servers, project/global instructions, machine, proxy route, repository commit and dependency lock. Do not put credentials in the report.

Inspect **resolved configuration**, not just `opencode.json`: defaults, remembered UI choices, agent overrides, project files and plugins can change the result. The currently documented CLI includes debug facilities, but consult your installed help before choosing a debug subcommand. Verify configuration effects against request metadata where possible.

The changelog viewed on this date lists `v1.18.35` at the top. Pin a tested release and dependencies rather than tracking a moving branch. Do not infer your installed version from this report. [7]

For Nix: pin the OpenCode package through `flake.lock`, enter the project development shell once, and benchmark from that shell. Prebuild the Sage/Macaulay2 environment before timing agent runs. Keep your existing compute resource limits; spawning more memory-heavy computations can increase total completion time through contention or failure. A new complete flake cannot be validated without your existing inputs and platform, so none is presented as tested here.

### Step 2 — Establish a minimal single-agent baseline

Temporarily remove optional orchestration plugins and unused MCP integrations from an isolated benchmark profile. Keep the native provider integration and the tools needed to inspect, edit and test. Confirm inherited global integrations are also absent: an empty project object is not proof that merged global settings disappeared.

Do not replace the built-in model-specific prompt with a large generic role prompt. Put project-specific requirements in a short `AGENTS.md`. OpenCode supports project/global instruction files and configured instruction paths [8]. MCP tool definitions can add context, so make integrations task-specific [9].

Suggested project instructions, to adapt rather than blindly impose:

```text
Complete the requested deliverable and verify the decisive acceptance criterion.
Read relevant code and project conventions before editing.
Use targeted searches and bounded excerpts; preserve full logs in files.
Batch independent reads. Serialize dependent edits and checks.
Use one agent by default; delegate only a clearly independent substantial task.
For research, state conventions and distinguish proof, computation and conjecture.
Use the project's approved compute wrapper for expensive calculations.
After a failed approach, identify new evidence before repeating it.
Stop when the acceptance criterion passes; report result, evidence and limitations.
```

A proposed starting budget is 300–800 tokens of project rules, excluding indispensable domain definitions. This is a heuristic to test, not a magic limit. Move large method guides into files loaded when needed. Do not count lines as tokens or remove scientific assumptions to hit a target.

### Step 3 — Make reasoning explicit

Begin the harness comparison at **matched effort**. Only after that baseline, try low effort for file edits, extraction and routine coding; medium for debugging; high for genuinely difficult derivations or unresolved conceptual steps. These are initial hypotheses, not demonstrated optimal choices.

Use the same capable model for an entire coherent task initially. Avoid a cheap-planner/strong-worker/reviewer cascade until it proves beneficial. A stronger model that finishes in fewer turns may use fewer total tokens.

Below is a **V1-style template**, based on documented option names [3]. Replace `MODEL_ID` with an exact available native OpenAI model ID supporting these options. It is JSON-parseable but has not been loaded by OpenCode here. Merge deliberately with your existing permissions; this does not set a security policy.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "openai/MODEL_ID",
  "provider": {
    "openai": {
      "models": {
        "MODEL_ID": {
          "options": {
            "reasoningEffort": "medium",
            "textVerbosity": "low"
          },
          "variants": {
            "economy": { "reasoningEffort": "low", "textVerbosity": "low" },
            "balanced": { "reasoningEffort": "medium", "textVerbosity": "low" },
            "deep": { "reasoningEffort": "high", "textVerbosity": "low" }
          }
        }
      }
    }
  },
  "compaction": { "auto": true }
}
```

Do not apply OpenAI-only fields to arbitrary compatible providers. Check for agent overrides and explicit CLI variants. Lower visible verbosity is not equivalent to lower reasoning effort; suppressing displayed thinking is not proof of reduced reasoning usage. Avoid aggressive hard output caps, which can truncate edits or proofs.

V2-native configuration uses `providers`, model `settings`, and variants as an array of entries with an `id` and `settings`. Migration documentation says supported V1 forms are normalized, while some legacy fields are unsupported and nested mixing is bounded [10, 11]. Use one documented shape per nested entry; avoid rewriting everything solely for performance.

### Step 4 — Reduce the number and size of tool cycles

Use one discovery pass to locate relevant files, then read the useful ranges together. Run independent read-only commands in a batch. Do not split “find path”, “read function”, and “read adjacent test” into separate model decisions if all three needs are already known.

For numerical and algebraic work, make scripts produce a compact machine-readable summary:

```json
{
  "status": "failed",
  "check": "d2*d1 == 0",
  "degree": 3,
  "seed": 1729,
  "raw_log": "results/run-1729.log"
}
```

That is an output contract, not the result of a mathematical computation in this investigation. Include the ring, characteristic, grading, dimensions and script version where relevant. Save matrices and long CAS traces as files; return invariants, discrepancies and paths. On failure, retrieve relevant context around the diagnostic. Do not blindly use `head` or discard stderr.

Aim initially for 1–4k tokens per routine tool response, with an explicit way to retrieve more. Measure task success before retaining this limit. For large proofs or source passages, completeness can outweigh token savings.

Prefer a single script for a known deterministic pipeline. For independent I/O, bounded concurrency can reduce tool time; for CPU/RAM-heavy Sage jobs, benchmark concurrency against memory limits. More agents and more processes are different decisions.

Avoid frequent model-mediated polling of a long computation. Use a completion event or an appropriately blocking tool and return meaningful milestones. Re-reading an unchanged log every few seconds consumes both context and model calls.

### Step 5 — Preserve cache reuse without hoarding context

Keep initial instructions and tool schemas stable throughout a session. Put changing task state later. Avoid plugins that rewrite the system prompt each turn with timestamps, progress banners or reordered tool lists.

OpenAI's current caching documentation is generation-specific: keys, breakpoints, write charges and effort-update behavior differ by model. Supported newer models can use append-only configuration updates to change effort without changing the earlier prefix [4]. Do not assume a raw API feature is exposed by your OpenCode release. Audit the adapter before patching it; do not invent a config field.

Test cache behavior on a realistic multi-turn task: compare first request with subsequent requests, preserving session/model/tool configuration. Reusing a stable prefix is necessary, not a guarantee of a hit. Do not pad prompts or issue dummy keepalive generations merely to increase a cache percentage.

Compaction and pruning are a tradeoff: shorter context versus summary cost, lost evidence and broken prefix reuse. Start with automatic compaction. In V1, `prune` removes old tool outputs; the viewed documentation gives `false` as its default [12]. Test enabling it separately on long tool-heavy sessions. Do not declare it universally beneficial.

In V2, documented controls include `keep.tokens` and `buffer`, plus provider-dependent native compaction [13]. These are not interchangeable with V1 `reserved`/`prune`. Preserve a concise checkpoint containing decisions, conventions, failed attempts, outstanding questions and exact result-file paths. Start a fresh session for a genuinely new task, not after every tool call.

### Step 6 — Remove measured startup and network overhead

For repeated CLI invocations, compare normal execution with a persistent backend:

```bash
opencode serve --hostname 127.0.0.1 --port 4096
```

In another terminal, after verifying supported flags:

```bash
opencode run --attach http://127.0.0.1:4096 --model openai/MODEL_ID --variant balanced --format json 'YOUR BENCHMARK TASK'
```

This addresses documented MCP cold-start overhead [6]; it does not make the model reason faster or guarantee a warm provider cache. Benchmark process warmth and prompt-cache warmth as separate factors.

For a proxy setup, the official network guide requires bypassing the local server, for example `NO_PROXY=localhost,127.0.0.1`; preserve any other needed entries [14]. Test the actual OpenCode runtime route. A successful curl request through SOCKS does not establish that the runtime or WebSocket path supports the same configuration. Prefer a supported HTTP(S) proxy endpoint when available.

Record retry/backoff intervals before shortening timeouts: a shorter timeout can cause additional full attempts. Compare first response event, first visible text and full completion separately. A UI showing reasoning summaries earlier can feel faster without finishing earlier.

### Step 7 — Add sophistication only after a measured win

Introduce a specialist agent only for a substantial independent subproblem. Give it a bounded question, relevant file paths, required evidence and a concise output format. Count parent and child usage. Avoid automatically copying all history into each worker.

Keep a final independent mathematical check for high-risk claims, but use a deterministic invariant/test when one is available. Do not require a planner, librarian, researcher, writer, referee and auditor to touch every small task.

A sensible research task contract is: mathematical object and conventions; exact deliverable; allowed computation; acceptance invariant; and what to report if unresolved. For example, “construct these maps over this ring, check the composite vanishes, compute kernels in these degrees, and distinguish finite-field evidence from characteristic-zero proof.” This prevents efficient production of an answer to the wrong problem.

## 4. Tests actually run here

No live LLM generation benchmark was run. No API token count, cache-hit rate or Codex/OpenCode end-to-end speedup was measured. The following tests validate specific mechanisms only.

| Test | Result | What it establishes |
|---|---|---|
| Targeted log extraction | 1,240,049 bytes → 327 bytes; 99.974% reduction | Much smaller tool payload can retain the decisive diagnostic |
| Error-preservation check | Exact `degree=3 seed=1729` retained | Targeted extraction preserved known required evidence |
| Naive truncation counterexample | First 100 lines omitted the error | Shorter output alone is not a sound optimization |
| Eight local reads: separate vs batched processes, 21 repetitions | Median 7.567 ms vs 0.986 ms; identical output | Local subprocess overhead exists; this is not an LLM speedup |
| Replayed-context arithmetic | 660,000 vs 114,000 assumed input tokens over 12 turns | Earlier payload reduction can affect many subsequent requests |
| Source-feature checks | Four asserted features present | Proposed diagnosis accounts for existing implementation features |

The log fixture deliberately contains repetitive irrelevant output and one known error. Its reduction percentage is **not representative of arbitrary repositories**. Bytes are not model tokens. The timing test uses local `cat` processes and excludes inference, networking and SDK startup. The arithmetic assumes 3,000 fixed tokens and 8,000 versus 1,000 new tool-result tokens per turn, with full history replay and no compaction; it models logical input, not billed cache cost.

A test reproduction script and raw results are embedded in the appendices. Source-presence tests are conditional on the downloaded files being present; they do not execute TypeScript or validate configuration against a release schema. The JSON configuration is syntax-checked separately. Full OpenCode schema validation was unavailable: direct retrieval of the schema returned HTTP 403.

## 5. The live benchmark that can establish parity

### Experimental design

Use your machine and authenticated clients, separate disposable worktrees with identical starting commits, and preinstalled dependencies. Run the same task prompt and external validator in each arm:

| Arm | Purpose |
|---|---|
| C: Codex CLI, explicit model/effort | Reference harness |
| O0: Current OpenCode setup | Captures the actual problem |
| O1: Minimal OpenCode, matched model/effort | Isolates optional configuration overhead |
| O2: O1 with selective output and batched reads | Tests tool/context efficiency |
| O3: O2 with lower effort on routine tasks | Tests an additional efficiency/quality tradeoff |

Keep authentication route, endpoint, serving tier and machine constant where possible. If they cannot match, label the difference as a product-stack comparison. Hosted Work is an additional reference, not a replacement for the controlled local comparison.

Choose six fixed tasks: a small edit, multi-file bug fix, repository navigation question, structured log diagnosis, bounded CAS computation, and difficult mathematical reasoning with independently checkable claims. Include hidden edge-case checks for coding and explicit conventions for mathematics. Do not grade mathematics solely with another LLM's approval.

Pilot one task per arm to validate instrumentation; then run at least five paired repetitions per task, randomized/interleaved in order. This is an initial screen, not a claim of statistical sufficiency. Expand only borderline or variable comparisons. Keep provider-cache cold/warm experiments separate; a new session does not guarantee a cold server-side cache. Record observed cache usage instead of assuming it.

### Capture

OpenCode documents `run --format json`, session export and usage statistics [6]. Codex documents noninteractive JSON events [15]. Verify flags on the pinned clients before scripting. Illustrative commands:

```bash
opencode run --model openai/MODEL_ID --variant balanced --format json 'TASK' > opencode-events.jsonl 2> opencode-stderr.log
codex exec --json -m MODEL_ID -c 'model_reasoning_effort="medium"' 'TASK' > codex-events.jsonl 2> codex-stderr.log
```

Use a monotonic external timer around each invocation. Record timeout and failure, not just successful process exits. Run the validator outside the agent after completion; a zero CLI exit status is not task success. Save full event logs, configuration hashes, repository diffs, validator output and provider usage. Track child sessions, compaction, title generation and other auxiliary model calls where exposed. If those costs are inaccessible, label totals as partial.

### Normalize and decide

Produce one row per task/arm/repetition with:

```text
arm, task, repetition, model, effort, auth_route, cache_condition,
wall_seconds, first_event_seconds, success, timeout, model_requests,
tool_calls, input_total, cache_read, cache_write, output_total,
reasoning_subset, retries, compactions, usage_complete
```

Compute paired per-task ratios before pooling heterogeneous tasks. Report medians, spread and bootstrap intervals when the sample supports them. Include failure rate and budget spent on failures; do not quietly drop timeouts. Do not call a p95 stable from five observations.

A proposed engineering acceptance target is: **no observed correctness regressions on the fixed suite, OpenCode median completion time within 10% of Codex, and normalized token use within 10% or better**. Those thresholds are your benchmark targets, not measured outcomes. A small suite cannot prove equal research quality. Inspect all mathematical failures individually.

Use one-factor ablations: effort, prompt length, MCP set, attachment mode, pruning, batching. Keep an intervention only if it improves the quality-constrained token/time tradeoff. If tokens improve but latency worsens, retain separate “economy” and “fast” profiles rather than pretending one optimum exists.

## 6. Recommended first session on your machine

1. Freeze current setup and save one representative slow session's raw usage and timings.
2. Match Codex's exact model and effort in native OpenCode; confirm resolved values.
3. Run a minimal one-agent profile with short project rules and required tools only.
4. Replace raw CAS/log dumps with summaries plus recoverable file paths.
5. Compare routine tasks at low versus medium effort; keep difficult mathematics separate.
6. Test persistent backend operation if startup is a visible part of wall time.
7. Investigate cache/transport modifications only if traces show a remaining problem.

The unresolved measurement is your actual configuration's overhead. This report provides a concrete baseline and tests, but an authenticated paired benchmark is still required to say how much of your observed gap has been closed.

## Sources

All accessed 9 October 2026. Primary documentation and first-party source code only. Recommendations and test design are this report's synthesis; documentary features are not evidence of a measured speedup.

1. [OpenAI: latency optimization](https://developers.openai.com/api/docs/guides/latency-optimization).
2. [OpenAI: reasoning models](https://developers.openai.com/api/docs/guides/reasoning).
3. [OpenCode V1: models and variants](https://opencode.ai/docs/models/).
4. [OpenAI: prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching).
5. OpenCode source retrieved at `v1.18.35`: [provider.ts](https://github.com/anomalyco/opencode/blob/v1.18.35/packages/opencode/src/provider/provider.ts), [transform.ts](https://github.com/anomalyco/opencode/blob/v1.18.35/packages/opencode/src/provider/transform.ts), [system.ts](https://github.com/anomalyco/opencode/blob/v1.18.35/packages/opencode/src/session/system.ts). File hashes below preserve the inspected bytes; the release tag is not an independently verified immutable commit.
6. [OpenCode CLI](https://opencode.ai/docs/cli/).
7. [OpenCode changelog](https://opencode.ai/changelog).
8. [OpenCode instruction rules](https://opencode.ai/docs/rules/).
9. [OpenCode MCP servers](https://opencode.ai/docs/mcp-servers/).
10. [OpenCode V1–V2 migration](https://opencode.ai/v2/docs/migrate-v1).
11. [OpenCode V2 models](https://opencode.ai/v2/docs/models).
12. [OpenCode V1 configuration](https://opencode.ai/docs/config/).
13. [OpenCode V2 compaction](https://opencode.ai/v2/docs/compaction).
14. [OpenCode network configuration](https://opencode.ai/docs/network/).
15. [Codex noninteractive mode](https://learn.chatgpt.com/docs/non-interactive-mode).

## Appendix A — Reproduce the offline checks

Save this code as `verify_strategy.py`, then run `python3 verify_strategy.py`. Requires Python 3, ripgrep and cat. It creates temporary fixtures, performs no network calls and makes no model requests. Source checks run only when the named release files are present beside the script.

```python
import json, pathlib, subprocess, tempfile, time, statistics, hashlib

def run_checks():
    results = {}
    with tempfile.TemporaryDirectory() as d:
        p = pathlib.Path(d)/'compute.log'
        lines = [f'INFO iteration={i:05d} rank=128 residual=0 checkpoint=unchanged\n' for i in range(20000)]
        lines.insert(17891, 'ERROR invariant d2*d1 != 0 at degree=3 seed=1729\n')
        p.write_text(''.join(lines))
        full = p.read_bytes()
        selected = subprocess.run(['rg','-n','-C','2','ERROR|FAILED|Traceback',str(p)],capture_output=True,check=True).stdout
        assert b'degree=3 seed=1729' in selected
        assert b'degree=3 seed=1729' not in b'\n'.join(full.splitlines()[:100])
        results['targeted_log'] = {'full_bytes':len(full),'selected_bytes':len(selected),'reduction_percent':round(100*(1-len(selected)/len(full)),3),'evidence_preserved':True,'head_100_misses_error':True}
        paths=[]
        for i in range(8):
            f=pathlib.Path(d)/f'{i}.txt';f.write_bytes((f'fixture {i}\n'*100).encode());paths.append(str(f))
        sequential=[];batched=[]
        for repeat in range(21):
            for mode in (['sequential','batched'] if repeat%2==0 else ['batched','sequential']):
                t=time.perf_counter()
                if mode=='sequential':out=b''.join(subprocess.run(['cat',p],capture_output=True,check=True).stdout for p in paths)
                else:out=subprocess.run(['cat',*paths],capture_output=True,check=True).stdout
                elapsed=time.perf_counter()-t
                assert out==b''.join(pathlib.Path(p).read_bytes() for p in paths)
                (sequential if mode=='sequential' else batched).append(elapsed)
        results['local_process_batching']={'repeats':21,'sequential_median_ms':round(statistics.median(sequential)*1000,3),'batched_median_ms':round(statistics.median(batched)*1000,3),'identical_bytes':True,'scope':'process startup only; no model calls'}
    n=12; fixed=3000; big=8000; small=1000
    def inputs(size):return sum(fixed+i*size for i in range(1,n+1))
    assert inputs(big)-inputs(small)==(big-small)*n*(n+1)//2
    results['context_arithmetic']={'assumed_turns':n,'large_result_tokens':big,'small_result_tokens':small,'total_input_large':inputs(big),'total_input_small':inputs(small),'saved_input_tokens':inputs(big)-inputs(small),'scope':'analytical illustration, NOT tokenizer or API measurement'}
    results['source_checks']={}
    for file,needle in [('release-provider.ts','return sdk.responses(modelID)'),('release-transform.ts','result["promptCacheKey"] = input.sessionID'),('release-system.ts','return [PROMPT_CODEX]'),('release-transform.ts','reasoning.encrypted_content')]:
        p=pathlib.Path(file)
        if p.exists():
            assert needle in p.read_text()
            results['source_checks'][file+':'+needle]={'present':True,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
    return results
if __name__=='__main__': print(json.dumps(run_checks(),indent=2))
```

## Appendix B — Raw verification results

```json
{
  "targeted_log": {
    "full_bytes": 1240049,
    "selected_bytes": 327,
    "reduction_percent": 99.974,
    "evidence_preserved": true,
    "head_100_misses_error": true
  },
  "local_process_batching": {
    "repeats": 21,
    "sequential_median_ms": 7.567,
    "batched_median_ms": 0.986,
    "identical_bytes": true,
    "scope": "process startup only; no model calls"
  },
  "context_arithmetic": {
    "assumed_turns": 12,
    "large_result_tokens": 8000,
    "small_result_tokens": 1000,
    "total_input_large": 660000,
    "total_input_small": 114000,
    "saved_input_tokens": 546000,
    "scope": "analytical illustration, NOT tokenizer or API measurement"
  },
  "source_checks": {
    "release-provider.ts:return sdk.responses(modelID)": {
      "present": true,
      "sha256": "9fb8958a521bbc5a70e5e6d4ecb130149115fe891fb78bca0ae73a966b9f547a"
    },
    "release-transform.ts:result[\"promptCacheKey\"] = input.sessionID": {
      "present": true,
      "sha256": "ddfea009d85f61172d056216addeeabd920cd368d4d27b2f652629f7e3bcb0d2"
    },
    "release-system.ts:return [PROMPT_CODEX]": {
      "present": true,
      "sha256": "7257f0660202d3e5d7ef86ee48cb4e51d5d0aa67703c274b8eb840b8ae307bbc"
    },
    "release-transform.ts:reasoning.encrypted_content": {
      "present": true,
      "sha256": "ddfea009d85f61172d056216addeeabd920cd368d4d27b2f652629f7e3bcb0d2"
    }
  }
}
```
