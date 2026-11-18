# Difficulty rubric (research profile)

Grade the task as written on its card, not the parent problem. The grade sets the starting tier, together with the task's priority and how many tasks wait on it. The benchmark (`bench report`) shows where this rubric is miscalibrated.

| Grade | Meaning | Typical examples | Prior start tier |
| --- | --- | --- | --- |
| 1 | Trivial. One lookup or mechanical transformation. Checkable at a glance. | grep for a parameter, reformat a table, unit conversion, extract numbers from a log | luna |
| 2 | Easy. Well specified, standard recipe, easy to verify. | plot existing data, fit a standard model, small script with clear I/O, summarise one paper section | luna |
| 3 | Medium-light. A standard method on non-standard specifics. Verification needs recomputation. | textbook derivation in this paper's conventions, numerical integration with a tricky region, compare three papers' definitions | terra |
| 4 | Hard. Non-trivial derivation or a novel combination of methods. Several interacting pitfalls. | derive a new effective description, design an estimator with controlled bias, debug a subtle numerical instability | sol |
| 5 | Hardest. Open-ended; needs a design decision or a new idea; may be unsolvable as stated. | choose and justify an approximation scheme, find why two methods disagree | sol (astra only after sol fails, and only for P1) |

## Modifiers

- **+1** if inputs are ambiguous or conflict with each other.
- **+1** if a wrong answer would look plausible (also raise the verification level).
- **-1** if a trusted worked example for exactly this exists in the workspace (recon trust A).
- Cap at 1-5.

## Getting the first tier right

A wrong first choice costs in two directions. Too low: a wasted attempt, a verification round, and a delay for every task that waits on this one. Too high: money on every such task. The router weighs both, with time weighted more on the critical path and for P1. So:

1. Run `bench similar` for context. Submit your own rubric grade and relevant tags.
2. The ledger does not adjust the grade from benchmark history. Use `bench route` or `bench report` to review the evidence before making a manual change.
3. Start difficulty 4 at Sol Low or Sol High, difficulty 5 at Sol High, and never start P1 at Luna. Historical IDs `luna`, `terra`, `sol`, and `astra` mean Medium, Medium, High, and xhigh; `terra-low`, `sol-low`, and `astra-max` identify distinct deployments.
4. Prefer splitting a grade-4 task into grade-2 and grade-3 pieces when a clean split exists. Cheap parallel work beats one expensive serial task.
5. During execution, the working grade changes only through a manual ledger update with a reason. A clean verified Luna solve or checked failures at distinct main tiers can inform that decision; incomplete results and uncleared gates cannot.
6. Keep the original difficulty in `bench outcome` across escalations. A working regrade changes routing guidance, not priority, verification requirements or Astra eligibility. Never treat a successful probe as completion of the main task.

## Astra

Astra xhigh is never a starting tier. It is reached only when a priority-1 task has failed at Sol High. For non-P1 tasks, a Sol High failure means re-scope, split or drop. Astra Max is available but never automatic: the user must explicitly approve the escalation, and both Sol High and Astra xhigh must already have failed on the same P1 task. Terra Medium is benchmark-only, regardless of measured results.

## Task types

`lookup`, `literature`, `derivation`, `numerics`, `code`, `analysis`, `explore`, `other`. Keep to these: the benchmark pools data by type and difficulty, and with eight types and five grades the cells fill up within a few projects. A new type starts from zero data.
