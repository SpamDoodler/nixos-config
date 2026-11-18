---
name: Writing genres
description: "How physics papers, mathematics papers, lecture notes and research reports differ in purpose, structure, tone, level of mathematical detail and motivation. Load when choosing a genre, outlining, drafting or judging a document, then read the genre's file in this skill's directory."
---

# Writing genres

Choose the genre from **who will judge the document**, not from the topic. A result in mathematical physics written for a physics journal is a physics paper; the same result for a mathematics journal is a mathematics paper, with different structure, different claims and a different rigor standard.

Read the file for the genre you are writing:

| Genre | File | One-line purpose |
| --- | --- | --- |
| `physics-paper` | `physics-paper.md` | Convince physicists that a result about nature or a model is true and matters |
| `math-paper` | `math-paper.md` | State precise results and prove them so a specialist can check every step |
| `lecture-notes` | `lecture-notes.md` | Give a master's student every prerequisite for a project, without gaps, at a walking pace |
| `report` | `report.md` | Tell a colleague or decision-maker what was found, how sure we are, and what is open |

## How the genres differ

| | Physics paper | Mathematics paper | Lecture notes | Research report |
| --- | --- | --- | --- | --- |
| Leads with | The physical question and the answer | The main theorem, informally then exactly | What the reader will be able to do | The answer and how sure we are |
| Unit of argument | Result supported by derivation, numerics, comparison | Definition, lemma, theorem, proof | Motivation, example, definition, theorem, example, exercise | Finding, evidence, caveat |
| Rigor standard | Physics level: the `rigor` skill, level P | Mathematical level: every stated result proven or cited exactly | Correct, but proofs only where they teach | As established; evidence levels explicit |
| Mathematical detail in the main text | Only what carries the argument; long derivations go to appendices | Complete. Proof sketches before long proofs | Every step a student cannot fill in themselves | Minimal; point to the research files |
| Motivation | Physical: what we can now predict, explain or measure | Mathematical: what was open, why it is hard, what the method opens up | Pedagogical: why we need this concept, shown on an example | Practical: what this decides |
| Hedging | Uncertainty stated as error bars, regimes and approximations | Nearly none: proven, conjectured, or not claimed | Little; flag what is beyond the course | Explicit evidence levels |
| Voice | "We", active, results-forward | "We", precise, economical | Direct, "we" or "you", patient | Plain, skimmable, answer first |
| Figures | Central: often the main evidence | Occasional, for intuition | Many: diagrams, worked examples | Tables and one or two key plots |
| Length | Venue limit | As needed for complete proofs | Long is fine; gaps are not | Short |
| Research artifacts (files, task or claim ids, agents) | Never | Never | Only in marked "project pointer" boxes | Allowed |

## Self-containment

The research files are scaffolding. Readers of a paper never see them, so the paper must stand alone.

- **Papers (physics and mathematics): fully self-contained.** No file paths, task ids, claim ids, evidence levels, or mentions of verifiers, agents or the research process. Every result the paper relies on is derived or described in the paper (main text or appendix), or cited from the literature. Numerics are described by method, parameters, resolution and convergence checks, the way a methods section or appendix would. If code or data are to be shared, a one-line availability statement says so; it does not point into the workspace.
- **Lecture notes: self-contained in content.** A student must be able to learn everything from the notes. Pointers to project files are tolerated only in clearly marked boxes ("In the project: ...") that the student can skip without losing anything.
- **Reports: may cite research files and task ids freely**; that is what makes them useful to colleagues.

The `stylecheck` tool counts references to research artifacts and placeholders for each genre. A final paper draft has zero of both.

## Mixed cases

- **Physics derivation, mathematics venue.** Only results with mathematical-level support may be called Theorem or Proposition. Everything else is a Conjecture, or a "formal computation" stated as such, often in its own section. Check the evidence level in `EVIDENCE.md` against the label.
- **Rigorous result, physics venue.** State it as a physical result first, with the physics it explains. Put the rigorous statement and proof where a mathematician can find them (a theorem box, or an appendix), and say in one sentence what rigor adds.
- **Notes from a paper.** Lecture notes are not a paper with exercises added. Re-order for learning: example before generality, motivation before definition, the main idea before the technicalities.

## Picking the genre

The brief names it. If it does not, ask (interactive) or infer from the venue and audience and say which you chose (under /goal).
