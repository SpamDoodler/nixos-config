# CLAIMS.md template

The claim ledger. The final report may only state claims that appear here, at the evidence level shown. Maintained by the orchestrator after every verdict.

```markdown
# Claims

| id | claim (one sentence, with its conditions) | formulation | status | evidence level | tasks | notes |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | | F1 | conjecture / supported / verified / refuted | 1-5 (see the research-verification skill) | T004, T009 | |
```

Status:

- `conjecture`: stated by a worker, not yet verified.
- `supported`: verified at V1 or V2.
- `verified`: verified at V3 or V4.
- `refuted`: a verified result contradicts it. Keep the row; refuted claims are part of the answer.

When two claims conflict, both drop to `conjecture` until resolved.

For L scope, track each substantive claim's target rigor, Lean file and
declaration, and certificate status and evidence separately from its V-level.
Certified claims require a matching statement, replay and axiom audit under
the `rigor` skill. Do not promote an uncertified L claim as established.
