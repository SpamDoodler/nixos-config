---
name: exact-computation
description: Perform symbolic or numerical mathematical computations with explicit assumptions, reproducible evidence and resource bounds
---
State the mathematical question, domains, assumptions and acceptance criteria.
Preserve integers, rationals and symbolic expressions exactly where possible;
introduce floating point deliberately, stating precision and tolerances.
Separate a general proof from finite checks, numerical evidence and conjecture.
Prefer small independent consistency checks and counterexample searches to
rerunning the same calculation. Record seeds and relevant software versions.
Follow project execution/resource guards; never bypass a required wrapper.
For potentially expensive work, estimate memory/time, start with a small
case, use project-approved bounds, and avoid concurrent memory-heavy jobs.
Use inherited TMPDIR for scratch. Keep requested reproducible deliverables
in the project, with commands and inputs sufficient to reproduce results.
Report exact results, numerical uncertainty, proof status and limitations.
