# PLAN.md template (research profile)

Written after framing. Interactive sessions: confirmed by the user, then frozen. Under /goal: frozen by the orchestrator, with its interpretation and assumptions listed at the top of `STATUS.md` for the user to correct. Changes go in `decisions.md` with a reason.

```markdown
# <project title>

## Goal
<as given, plus the interpretation chosen in FRAMING.md>

## Success criteria
- Answer form: <from FRAMING.md>
- Rigor: physics level, except <claims that need math level>
- A negative result counts if: <condition>

## Portfolio
| Formulation | Spike tasks | Decision rule after the spikes |
| --- | --- | --- |
| F1 | T00x, T00y | continue if <...>, drop if <...> |

## Non-goals
<what we are deliberately not doing>

## Assumptions
| # | Assumption | How it could be falsified | Cheapest test |
| --- | --- | --- | --- |

## Kill criteria (written before work starts)
- Stop or reframe a branch if <condition>, e.g. "8 verified tasks on F2 without a supported claim".
- Stop the project and report if <condition>, e.g. "no formulation survives its spikes".

## Budget
- Max tasks: <n>   Concurrency: 5   Cost cap (relative units, tiers.json): <n>
- Astra: escalation for P1 tasks only; at most <n> astra attempts in total.
```
