# Lecture notes: prerequisites for a project

**Purpose.** A master's student reads these notes and afterwards knows everything they need to start working on the project. Nothing they need may be missing, and nothing may be skipped because it is "standard". Length is fine. Gaps are not.

The reader is a capable student with a stated baseline (in the brief, for example: undergraduate quantum mechanics, electrodynamics, linear algebra, real analysis). Anything beyond the baseline that the project uses must be explained in the notes.

## Planning: the prerequisite map

Before any drafting, build the map (the architect does this in `STORY.md`):

1. **Inventory.** List every concept, result, technique and piece of notation the project uses, from the research output: the definitions, the approximations, the standard results the derivations lean on, the numerical methods, the conventions.
2. **Baseline cut.** Mark each item as *assumed* (inside the stated baseline) or *to teach*. When in doubt, teach it. The notes open with an explicit "What you should already know" list, so a student can check themselves and look up anything missing.
3. **Dependencies.** For each item to teach, list what it needs. Order the chapters so that nothing is used before it is introduced. Draw the map as a short dependency list at the start of the notes, so the student sees the route.
4. **Depth per item.** For each item decide: *use it* (the student needs to apply it: full treatment with worked examples and exercises), *recognise it* (needs to know what it is and when it applies: definition, one example, the main statement), or *trust it* (a result taken from the literature: precise statement, conditions, reference, intuition for why it holds).

## Structure

1. **Front matter.** Who the notes are for, the baseline, the route through the chapters (the map), and one paragraph on the project each chapter prepares for.
2. **Per chapter:**
   1. *Where we are*: what the chapter builds on, by name, and the question it answers.
   2. *Learning goals*: three to five, concrete ("compute", "recognise when", "derive").
   3. *A motivating example or problem* that earlier tools cannot handle.
   4. *The idea*, on that example first, then in general.
   5. *Definitions and results*, each followed by an example.
   6. *Worked examples*, from routine to one that needs thought, every step shown.
   7. *Common mistakes*, stated explicitly.
   8. *Summary*: what to remember, a formula sheet if useful.
   9. *Exercises*, graded, with answers or hints for most.
   10. *Connection to the project*: one paragraph on where this appears in the project.
3. **Notation table and index of concepts** at the end.

## Pace and tone: pedestrian on purpose

- **Small steps.** Write out every algebraic step a student could get stuck on. If a step uses an identity, name it and say where it comes from. "It follows that" is only allowed when it follows in one line.
- **No "clearly", "obviously", "it is easy to see", "standard".** If it were obvious to the student, it would not need writing down.
- **Concrete before abstract.** An example before the general definition, every time.
- **Explain why**, not only that: why this definition, why this step, why this approximation is allowed here.
- **Redundancy is a feature.** Restate a definition when it is used again chapters later. Recap before building on something. A lengthy text with no gaps beats a short one with holes.
- **Every symbol introduced in words** at first use and listed in the notation table; the same symbol means the same thing in every chapter.
- **Proofs where they teach.** Prove what the student will need to reproduce or adapt. For results they only need to trust, give the precise statement, conditions, a reference and an intuitive argument.
- **Further reading.** Include a short, annotated selection researched by `w-literature`, grouped by chapter or topic. Give precise locators and tell readers which reference to use for a gentler explanation, a worked example, or a deeper treatment. Keep this optional and keep citations at the point of use.
- Direct, friendly voice ("we", "you" in exercises). Short paragraphs. Diagrams early and often.

## The gap test

A draft passes when a reader with exactly the stated baseline can go from the first page to the last without needing anything else. `w-reader` runs in `gaps` mode for this: it lists every term, result or step it could not follow from the notes plus the baseline. Each item is either taught, moved to the baseline list, or given a precise reference with a "you may trust this" note. The list must be empty before the notes are final.

## Common failures

- Research-paper order: general definition first, example never.
- "It is easy to see" where it is not.
- A concept used in chapter 5 that was never introduced, because the writer knew it.
- Exercises that only test recall.
- Notes that summarise the literature instead of teaching it.
