# Research under /goal


How native `/goal` works (opencode 2.2.1+): after each round a reviewer, running on this session's own model, reads the whole history, including tool results, and returns `done`, `continue`, `blocked`, `paused` or `wait`. A round counts as stalled if you made no tool calls since the last continuation, or if the reviewer gives the same reason twice in a row. Three stalled rounds pause the goal, and there is a hidden cap of 50 rounds. While your own background subagents run, the reviewer is not asked; their reports wake you.

So:

- **Read `research/GOAL.md` first** if the objective points to it. The objective itself is capped at 4,000 characters, so the details live in that file.
- **Ad-hoc goals.** If the objective is all you have (no `GOAL.md`), write `research/GOAL.md` yourself from it in the first round, using the `research-goal` skill's template. Fill in why, answer form, rigor and budget with explicit assumptions (default budget: 30 tasks, 3 astra attempts), and list those assumptions at the top of `STATUS.md`. Then proceed; do not wait for answers.
- **End your turn while subagents run.** Do not invent busy work. When nothing is ready and workers are running, give the progress update and stop; a report will wake you.
- **Make every round different.** Each round should change the ledger, the claims or the plan. If the same blocker comes up twice, act on it (re-scope, drop, ask the strategist) rather than restating it; a repeated reason counts as a stall.
- **Progress update.** End every round with `ledger status` using `focus`, `active_routes`, `changed`, `blockers`, and `next` as relevant. It appends the progress block to `STATUS.md`. Summarize it in your reply, especially the main problems and what each active approach is testing. Don't repeat unchanged details or wait silently after opening a batch.
- **Long tasks.** A goal also pauses after 30 minutes idle waiting on background work, and on a server restart. Keep tasks small enough to finish well inside that; the step caps help. After any pause, `/goal resume` continues from the files.
- **Completion.** The reviewer is the same model as you, so give it evidence, not assertions. When finished, end `STATUS.md` with this block and repeat it in your reply:

```
GOAL CHECK
[x] research/report/REPORT.md answers the goal in the form promised in FRAMING.md (or states a supported negative result)
[x] every headline claim in REPORT.md is in CLAIMS.md at V3 or higher; every other claim it uses at V2 or higher
[x] integration verification: no unresolved conflicts (research/integration.md)
[x] r-strategist final: accept (research/strategy/final.md)
GOAL CHECK: PASS
```

  Tick only what is true, with the file that shows it. If the budget is spent or every formulation is blocked, write a partial report and end with `STATUS: BLOCKED` and exactly what would unblock it.

  For L scope add a required item: every substantive claim in that scope has
  a matching, replayed Lean certificate with an axiom audit recorded in
  `CLAIMS.md`. Do not emit `GOAL CHECK: PASS` if that item is unmet.
