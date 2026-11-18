# Findings and the report

## Finding schema

```
### F<n>: <short title>
- Location: <file>:<lines> / Eq. (n) / Sec. x / claim C<k>
- Kind: WRONG | GAP | APPROX | UNCLEAR | INCONSISTENT | EXPOSITION | NIT
- Level: PHYSICS | MATH | BOTH   (the rigor standard at which this is a problem)
- Severity: BLOCKING | MAJOR | MINOR | NIT
- Load-bearing: yes (<which main claims>) | no
- Fixability: LOCAL (a few lines) | REPAIR (needs an extra argument) | STRUCTURAL (the approach may not work) | UNKNOWN
- Confidence: high | medium | low
- Evidence: <what was done: blind re-derivation, limit checked, numeric test, literature>
- Problem: <what is wrong, stated so a reader can re-check it in two minutes>
- Origin: WRITING | RESEARCH | CONFLICT | UNTRACEABLE   (from the trace step; see procedure.md)
- Resolution attempt: <tier and result, if one was made>
- To resolve: <what must be shown or changed, and by whom: the writer or the research team>
```

Definitions:

- `WRONG`: the claim is false or the step is invalid in this setting. Give a counter-check.
- `GAP`: probably true, but a needed step is missing at the target rigor.
- `APPROX`: an approximation used without justifying its regime, or outside it.
- `UNCLEAR`: you cannot tell, because a definition, notation or step is ambiguous.
- `INCONSISTENT`: conventions, notation or numbers disagree between places.
- Severity: `BLOCKING` if the main result is false or unsupported as stated because of this. `MAJOR` if load-bearing and wrong or gapped but the main result plausibly survives repair, or if a stated result is wrong though not load-bearing. `MINOR` if not load-bearing. `NIT` for presentation and typos.

A gap that is fine at physics level but would not pass at mathematical level is **not a finding**. It goes in the rigor-notes table (one line: location, what the mathematical version would need, and whether that is routine, hard or open).

## REPORT.md structure

1. **Verdict.** Three sentences: does the main result stand as argued, how many BLOCKING and MAJOR findings, and the single most important thing to fix.
2. **What still has to be solved**, in two lists:
   - **Research obligations** (origin RESEARCH or CONFLICT): precise statements of what must be derived, computed or checked, each with location, kind (math or physics), fixability and a suggested route. Also written to `FOLLOWUP-research.md` in a form the research agent can take as a goal.
   - **Writing fixes** (origin WRITING): what the document must add or correct, with the research file that already has it. Also written to `FOLLOWUP-writing.md` for the writer.
   - UNTRACEABLE findings go in whichever list the lead judges right, marked as such.
3. **Findings table.** id, location, kind, level, severity, fixability, origin.
4. **Findings in detail**, most severe first.
5. **Rigor notes.** The P-acceptable, M-incomplete table.
6. **Coverage.** Which claims were checked and by what method (evidence ladder in the `rigor` skill), which were not, and the UNRESOLVED list.
7. **Verified solid.** Claims that passed, each with its evidence level. Never write "verified" without saying how.
