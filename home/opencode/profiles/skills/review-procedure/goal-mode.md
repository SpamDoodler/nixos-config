# Review under /goal



The /goal reviewer is this session's own model and reads the whole history. A round stalls if you made no tool calls or the same reason repeats; while your subagents run, the reviewer waits, and their reports wake you. So: end your turn while checks run; make each round move the review forward (map, plan, checks, triage, report); write one status line per round in `review/<slug>/STATUS.md` and your reply: `ROUND n | phase | checks done a / running b | findings: blocking x, major y | next: <what>`.

If the objective names no depth or rigor, use `standard` and `P` and say so in the first status line.

Done only when `review/<slug>/STATUS.md` ends with:

```
REVIEW CHECK
[x] review/<slug>/claims.md maps every main result
[x] every load-bearing claim was checked by at least one method, or is listed as UNRESOLVED with its obstacle (Coverage section)
[x] every BLOCKING or MAJOR candidate was corroborated or downgraded, and every confirmed finding has an origin (WRITING / RESEARCH / CONFLICT / UNTRACEABLE)
[x] review/<slug>/REPORT.md, FOLLOWUP-research.md and FOLLOWUP-writing.md written
REVIEW CHECK: PASS
```

