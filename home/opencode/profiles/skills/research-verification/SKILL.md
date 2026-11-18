---
name: Research verification
description: "Verification levels V1-V4 for research results, integration checks, claim evidence levels, and how verdicts feed the benchmark."
---

# Verification in research

Verification is what makes the team's output trustworthy and the benchmark meaningful. It is also expensive, so its strength is matched to how much depends on the result.

## Levels

| Level | What happens | Who | Use for | Typical cost vs. the task |
| --- | --- | --- | --- | --- |
| V1 check | Each acceptance criterion tested with the verifier's own evidence (recompute, re-run, limit check) | the checker one model up (below) | Default. Results nothing important rests on | 20-40% |
| V2 independent route | V1, plus the key result obtained by a different method | the checker one model up, `independent` mode | Anything a claim in `CLAIMS.md` rests on | 50-100% |
| V3 blind replication | A second worker solves the same card without seeing the first; the checker compares the two | same-tier worker + the checker one model up, `compare` mode | Priority-1 results | about 100-150% |
| V4 adversarial | V3, then a red team tries to break the claim | V3 + `r-redteam` | Headline claims of the final report | about 150-200% |

## Who checks: one model up

| Work done by | Checked by | Why |
| --- | --- | --- |
| luna | `r-verifier-t` (terra) | A checker of the same model tends to share the worker's blind spots |
| terra | `r-verifier-s` (sol) | |
| sol | `r-verifier-s` (sol, fresh session); priority 1: `r-verifier-a` (astra) | Astra checks only where the conclusion depends on the result |
| astra | `r-verifier-s` (sol) | Not astra itself; a different model sees different things |

The `ledger` tool names the checker and refuses verdicts from a weaker one. If all four tiers are one model family, blind spots still correlate across tiers; pointing `r-verifier-s` at a model from another family (one line in its file) is the strongest single improvement to checking.

Rules of thumb:

- **Choose by consequence, not difficulty.** A hard task nothing depends on gets V1. An easy lookup that the main argument rests on gets V2.
- **Silent failure needs more.** If a wrong answer would look plausible (no limit to check, no known value to compare), go one level up.
- **Budget.** Across a project, verification typically takes 25-40% of spend. Much less means results are not being checked; much more means V3/V4 are used too widely.
- **Upgrades are cheap, downgrades are not.** A V1-passed result that becomes load-bearing later is re-verified at V2 before a claim uses it.

## Integration verification (before the report)

Pieces verified one at a time can still disagree: different sign conventions, different regimes, a normalisation that changed between tasks. Before synthesis the orchestrator runs:

1. `rv-consistency` across `CLAIMS.md` and the results it cites.
2. `rv-sanity` on every headline claim.

Any conflict downgrades the affected claims until resolved, and the affected outcomes are labelled in the benchmark (`bench label ... source=integration`).

## Rigor

Research results are judged at physics-level rigor (the `rigor` skill) unless `PLAN.md` says otherwise. A verifier does not fail a result for a standard formal step. It fails a result that is wrong, violates a limit or symmetry, uses an approximation outside its regime, or claims more than it shows.

For L, read `lean-certificates.md` in `rigor`. Give certificate production and
checking explicit task cards with appropriate shell permissions and pinned
toolchain instructions. V1–V4 are verification procedures, not substitutes for
Lean certification. Do not clear claim verification on prose or a build log
without also checking the statement and axioms.

## Feeding the benchmark

- `bench outcome` records the verifier's verdict and the level.
- When later evidence contradicts a verdict, record it with `bench label`: `source=replication` (a V3 disagreement), `downstream` (a task that used the result failed because of it), `integration`, or `human` (you).
- `bench report` then shows how often each verification level let a wrong result through. If V1 false passes are common for a task type, raise its default level.

## Claim evidence levels (used in `CLAIMS.md` and the report)

1. Independently re-derived (V3 or V4)
2. Verified by an independent route (V2)
3. Checked against the criteria (V1)
4. Consistent with other results, not otherwise checked
5. Conjecture (stated by a worker, not verified)

Headline claims need level 1. Other claims the report relies on need level 2 or better. Anything weaker is labelled as such in the report.
