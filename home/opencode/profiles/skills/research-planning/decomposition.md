# Organising a research program for parallel work

A wide task graph lets the orchestrator run many independent workers at once. Dispatch ready work within the agreed budget; the slot ceiling is not a reason to invent work or split it into redundant tasks. `ledger stats` reports the shape: parallelism (tasks divided by the longest chain), level widths, bottlenecks and slot utilisation.

## Patterns that create width

| Pattern | Use when | Shape |
| --- | --- | --- |
| **Contract first** | Several tasks must agree on notation, a definition, a normalisation, a data format or an interface | One small early task fixes it in a file; everything else depends on that file, not on each other |
| **Portfolio spikes** | The goal has several possible formulations | One cheap spike per formulation in parallel, each with a decision rule |
| **Split by case** | A derivation or computation covers several regimes, limits, symmetry sectors or parameter ranges | One task per case, plus a small merge task |
| **Method pairs** | A result matters | Analytic and numerical routes as two parallel tasks; agreement is the check |
| **Side lines** | Literature, conventions, sanity checks, tooling | Run them beside the main line from the start, not after it |
| **Map then reduce** | Many similar items (papers to digest, parameter points, examples) | Many tiny independent tasks, one aggregation task |
| **Skeleton then fill** | A long derivation | First a task that writes the outline of steps and the intermediate statements; then one task per step, all reading the skeleton |

## Anti-patterns that kill width

- **The relay.** Each task needs the previous one's result: A, then B, then C. Ask whether B needs A's result or only A's conventions. If only the conventions, put them in a contract.
- **The hub.** One big task everything waits on. Split it so its first part (the statement, the interface, a rough version) unblocks others early.
- **The kitchen sink.** One task with five deliverables. Split it; small tasks also route to cheaper models.
- **Hidden coupling.** Two tasks writing the same file, or one reading another's work in progress. Give each its own folder and a contract.
- **Late checks.** Cross-checks scheduled after the main line finishes. Schedule them alongside, against the contract.

## Targets

- Parallelism (tasks divided by critical path) of at least 2.5 for projects with eight or more tasks.
- Slot utilisation (from `ledger status`) above about 60% while there is work left.
- No task with more than a quarter of the project waiting on it, unless it is a small contract task.

Some problems are serial: an argument where each step really needs the previous result. Then say so with `ledger gate kind=structure note=...`, keep the chain on strong models (a failed cheap attempt on the critical path costs everyone's time), and run the cross-checks and literature in parallel with it.
