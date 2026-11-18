# Review procedure

## 0. Snapshot

Call `review_snapshot` with the workspace-relative manuscript path and review slug. For a multi-file manuscript, pass its directory so relative inputs and figures are copied together. Review only the copy at `review/<slug>/target/`. On resume, reuse the existing snapshot for that review; use a new slug to review a changed source. For `/review-bench`, use the planted snapshot the planter prepared. Do not ask the user to run `cp` as a routine step. Checkers are blind: they can read the snapshot and `review/`, not `research/` or `writing/`.

## 1. Map

Launch `rv-mapper` on the snapshot. It writes `claims.md`: each claim's location, kind, declared rigor, scope, candidate obligations, dependencies and load-bearing rating, plus conventions. Before checks, confirm the target rigor and concrete obligations in the map; record any explicit user override against the named claim. A claim is **load-bearing** if any main result depends on it.

## 2. Plan checks

For each load-bearing claim pick methods that test its obligations: blind re-derivation (`rv-derive`), sanity (`rv-sanity`), literature (`rv-lit`). Run `rv-consistency` once over everything. Non-load-bearing claims get only the cheap checks. Write `plan.md` with a check ID per run (S1, D1, L1, C1, ...), what each checks, and any obligation left uncovered. Give blind workers the obligations without revealing the answer.

For L, add a certificate entry to `claims.md` for every substantive claim
in scope, including supporting claims. Plan statement matching, replay and
axiom audit using `lean-certificates.md`; review depth controls supplementary
checks, not certificate coverage.

**Benchmark probes:** for every planned blind re-derivation, launch `rv-probe-luna`, `rv-probe-terra-low`, `rv-probe-terra` and `rv-probe-sol-low` together with the main run, even in lean mode. Use bounded batches and grade against the existing validated reference during triage; do not add Sol High or Astra runs just to grade probes. Terra Medium is benchmark-only. If a comparable run wasn't launched before the answer was exposed, report the missing coverage; don't backfill it as blind.

## 3. Check, in parallel

For each derivation, use one task ID (e.g. `D1`) and distinct run IDs (`D1-sol`, `D1-luna`, `D1-terra`, and `D1-sol-replica` if needed). Rate difficulty (1–5) before launching, using the research difficulty rubric and the work required **from the setup alone**. Record why and whether this is a reproduction from a known setup, not an open research problem. Give the agents identical `checks/<task>.setup.md`, target rigor, and acceptance criteria. In the same batch, give each a unique `<run>.mine.md` and tell it to derive from the setup only and stop. Do not share the manuscript, claimed answer, other reports, or hints in the blind launch. After all available blind attempts are saved, compare against the independently validated answer; do not count a solution reached after seeing the answer.

Log every launch with `bench rv_check review=<slug> check_id=<run> role=<role> tier=<tier> claims=[...]`. For the matched derive runs add `task_id=<task> difficulty=<rating> rigor=P|M|L`. Log every matched result, including failures and unresolved attempts, as described in `bench.md`.

Log `luna`, `terra-low`, `terra` and `sol-low` separately with unique IDs.
Use the same setup and acceptance criteria. These probes do not replace the
normal checks.

## 4. Triage (checks go one model up)

- Everything from Luna or Terra checkers is a candidate until you (Sol) have looked at it. A pass covers only the obligations actually checked. Neither a second derivation nor numerics clears an unchecked load-bearing assumption.
- Every BLOCKING or MAJOR candidate is corroborated by `rv-derive` (sol) or your own reading of the step. A cited-result mismatch from `rv-lit` needs you to read the cited passage.
- `rv-derive` results on load-bearing steps are corroborated by a second blind `rv-derive`; lower-tier runs do not substitute for it. Contested potential BLOCKING steps go to `rv-arbiter` (astra, at most three per review). You must be able to follow the arbiter's decisive argument, otherwise `confidence: low`.
- If extra justification is not required by the claim or the chosen standard, log it as a rigor note. Otherwise an established omission can be a finding even at P. Keep unchecked obligations unresolved, not passed.
- Log the fate of every candidate: `bench rv_findings review=<slug> items=[{id, check_id, tier, role, claim, kind, severity, status}]`, with status confirmed, downgraded, rejected or duplicate.

## 5. Trace: writing problem or research problem?

Only now, for each confirmed finding, launch `rv-trace` with the finding list. It looks in `research/` (claims, task results, verdicts, negative results) and `writing/` (evidence digest, story) and classifies each finding:

- **WRITING**: the research has the step or result, and the document omitted or misstated it. Fix in the text.
- **RESEARCH**: the research does not have it, or has the same gap. Needs new research.
- **CONFLICT**: document and research disagree. Someone is wrong; say which, if the trace can tell.
- **UNTRACEABLE**: the claim cannot be found in the research at all.

Check the trace one model up: for every BLOCKING or MAJOR finding, open the research files it cites and confirm the classification. Add `origin` to the finding and log it (`bench rv_findings` again with `origin`). Tracing comes after finding on purpose: reviewers who read the research first tend to accept the document's gaps as covered.

## 6. Resolve (benchmark and repair)

For confirmed GAP and APPROX findings of severity MAJOR or above (and BLOCKING ones of any kind if the user asked for repair), try to close the gap independently:

1. `rv-probe-terra` with role `resolve` and the finding; checked by `rv-derive` (sol) in check mode.
2. If that fails: `rv-probe-sol` with role `resolve`, carrying the failure summary; checked by a fresh `rv-derive`, or `rv-arbiter` if the gap is potentially BLOCKING.

Log each attempt: `bench outcome task_id=<slug>-<finding> type=gap-resolution tier=<tier> difficulty=<1-5> verdict=<checker verdict> checker_tier=<tier>`. A verified resolution turns a finding into a writing fix (the fix is known) or a much smaller research obligation.

## 7. Report

Write `REPORT.md` (structure in `report.md`), `FOLLOWUP-research.md` and `FOLLOWUP-writing.md`. Then give the user a short summary: verdict, counts by severity and origin, the top three things to fix.

## Not getting stuck

Every check has a step budget. A check that does not resolve is recorded as UNRESOLVED with the exact obstacle, and the review moves on. Small problems: one line, keep moving. Severity follows load-bearing position, not annoyance. You do not re-derive things yourself except to adjudicate.
