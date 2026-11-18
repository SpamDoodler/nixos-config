# Writing procedure

## Files (all under `writing/<slug>/`)

- `BRIEF.md`: genre, venue, reader, length, sources, rigor, format (`.tex` or `.md`), the message in one sentence (draft). For lecture notes also: the reader's baseline (what a master's student is assumed to know) and the project the notes prepare for.
- `EVIDENCE.md`: what may be claimed and how strongly (from `w-digest`).
- `STYLE.md`: the user's voice, if samples were given (from `w-digest`).
- `STORY.md`: message, reader, takeaways, paragraph-level outline, figure plan (from `w-architect`).
- `draft.tex` or `draft.md`, plus `figures/`.
- `reviews/`: reader, fidelity and style reports, one file per round.
- `STATUS.md`: one line per round, and the final check.

## Procedure

1. **Brief.** If `BRIEF.md` is missing, write it from the request. Interactive: confirm genre, reader and message with the user in one round of questions (the question tool). Under /goal: infer, write your assumptions at the top of `STATUS.md`, and proceed.
2. **Evidence.** Launch `w-digest` with the brief and the source folders (typically `research/` and `review/`, plus any reference the brief names). It writes `EVIDENCE.md`, and `STYLE.md` if voice samples are given. Read `EVIDENCE.md` yourself in full: it is short by design, and everything later rests on it. Because the digest is written by a cheaper model, check it one level up: compare every headline claim and five other randomly chosen claims against their source files, including the numbers. If any is wrong, send the digest back with the list.
3. **Story.** Launch `w-architect` with `BRIEF.md`, `EVIDENCE.md` and the genre. It writes `STORY.md`. Check it before drafting:
   - every outline claim maps to an `EVIDENCE.md` item at a level that supports it;
   - nothing rests on an open BLOCKING review finding;
   - in a math paper, every Theorem has mathematical-level support;
   - the first sentences of the outline's paragraphs, read in order, tell the story;
   - papers: the self-containment plan covers every result the paper relies on (derived in the text, in an appendix, or cited);
   - lecture notes: the prerequisite map covers every item in the digest's inventory, in an order where nothing is used before it is taught.
   Fix it with one follow-up to the same architect session (pass its `sessionID`), or edit it yourself.
4. **Figures and draft, in parallel.**
   - For each planned figure, launch `w-figure` with its one-line message and data sources.
   - Short documents (papers, reports): one `w-drafter` writes the whole draft in order. One voice matters more than speed here.
   - Long documents (lecture notes, theses): first write a notation table and a style sheet into `STORY.md`, then one `w-drafter` per chapter in parallel, each told the chapters before and after it. Then one continuity pass by a single drafter.
5. **Revision rounds** (at most three; stop earlier when clean):
   1. In parallel: `w-reader` (cold read; for lecture notes also in `gaps` mode with the brief's baseline), `w-fidelity` (claims against evidence, and self-containment), and the `stylecheck` tool for the genre with `slug` set.
   2. Write `reviews/round-<n>-memo.md`: what to change, **structure first** (message mismatch, order, missing motivation), then fidelity (overclaims, wrong numbers), then paragraphs. Leave sentence-level issues for the line edit unless they are the main problem.
   3. Send the memo as a follow-up to the drafter's session, so it revises with its own context. If the reader's one-sentence message differs from `STORY.md`, that comes first, before anything else.
6. **Line edit.** When structure and fidelity are clean: run `stylecheck`, launch `w-editor` with the flags and the style skill, then run `stylecheck` again and `w-fidelity` in `diff` mode on the edited sentences. Editing must not change what is claimed.
7. **Technical consistency.** For papers, launch `w-fidelity` on the final draft (notation, numbers between text, tables and figures, cross-references).
8. **Final check.** End `STATUS.md` with this block and repeat it in your reply:

```
FINAL CHECK
[x] w-reader: one-sentence message matches STORY.md (reviews/round-n-reader.md)
[x] w-fidelity: no overclaims, no unsupported claims, numbers match (reviews/round-n-fidelity.md)
[x] stylecheck: PASS, or each remaining WARN justified in STATUS.md (writing/<slug>/lint-history.jsonl)
[x] genre rules: rigor labels match evidence; required sections present
[x] self-contained: stylecheck shows 0 artifact references and 0 placeholders (papers); lecture notes: gap list empty (reviews/round-n-gaps.md)
[x] technical consistency: no unresolved items (papers only)
FINAL CHECK: PASS
```

## Model policy: checks go one model up

| Work | Done by | Checked by |
| --- | --- | --- |
| Evidence digest | `w-digest` (terra) | you (sol): spot-check against the sources |
| Story and outline | `w-architect` (astra) | you (sol), with the checklist in step 3 |
| Draft | `w-drafter` (sol) | `w-fidelity` (sol, fresh session) for claims; `w-reader` for readability |
| Figures | `w-figure` (terra) | you (sol): look at each PNG against its message; `w-fidelity` checks the numbers |
| Line edit | `w-editor` (terra) | `w-fidelity` (sol) in `diff` mode |

The exception is `w-reader` (terra). It is not a correctness check but a probe of readability, and it is deliberately weaker than the drafter: if it gets lost, a tired expert would too. Its reports are judged by you.

## Judging

- **Message first.** If a cold reader cannot state the main result after the abstract and introduction, the document has failed regardless of anything else.
- **Never strengthen a claim to make it read better.** The evidence level sets the wording (the style skill's hedging table). If the text needs a stronger claim to work, the fix is more research, not stronger words; say so to the user.
- **Cut.** Results that do not serve the message go to an appendix, the supplementary material or nowhere. A shorter document that makes one point well beats a complete one.
- **Self-contained output.** Papers never mention research files, task or claim ids, evidence levels, agents or the research process; what the reader needs is in the paper or cited. Lecture notes may point to project files only in marked boxes. Reports may cite research files freely. `EVIDENCE.md` ids are for internal bookkeeping and never appear in a paper.
- **Lecture notes are pedestrian.** Length is fine, gaps are not. If the gap test finds something missing, teach it; do not cut it to save space.
- **The user's voice.** If `STYLE.md` exists, it overrides generic style choices except the rules on hedging and fidelity.
