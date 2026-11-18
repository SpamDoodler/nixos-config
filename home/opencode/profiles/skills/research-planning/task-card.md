# Task card template

Copy to `research/tasks/<id>/card.md` and fill in. The worker has no other context. If it is not on the card, the worker does not know it.

```markdown
# <id>: <one specific line, findable later by `bench similar`>

## Context pack
- Goal: <the research goal in one line>
- Serves: <formulation F# / claim C# / sub-question, and how this task moves it forward>
- Glossary: research/FRAMING.md, section "Glossary for workers"

## Goal of this task
<One sentence: what this task produces.>

## Inputs (files that already exist)
- <path>: <what it is and which part matters>

## Output
- `research/tasks/<id>/result.md`, starting with an `## Interpretation` section, then <format and contents expected>
- <other files, in this folder only>

## Acceptance criteria (a verifier must be able to check each without asking anyone)
1. <criterion with a concrete check, e.g. "reproduces Eq. (4) of lit/smith2021 within 1% at g = 0.1">
2. <...>

## Out of scope
- <the tempting neighbouring problem, by name>

## Independence
- Do not read or depend on: <other task folders, in-progress files>
- Conventions: <notation, units, normalisation>

## Grading
- Type: <type>   Difficulty: <1-5>   Priority: <P1-P3>   Verification: <V1-V4>   Tier: <luna|terra|sol|astra>
- Failure summary from the previous tier (if escalated): <<= 100 words, or none>
```

## Checklist before launching

- [ ] A worker who has never seen the project could say, after reading only this card and the glossary, what it must produce.
- [ ] Inputs are files, not "the result of T003".
- [ ] Acceptance criteria are checkable; for `explore` tasks they say how many leads and what evidence each needs.
- [ ] The task owns its output folder.
- [ ] Out-of-scope names the tempting adjacent problem.
- [ ] The task fits its tier's step cap. If you doubt it, split it.
