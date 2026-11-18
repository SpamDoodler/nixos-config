---
description: "Prepare a document with you before writing starts: writes writing/<slug>/BRIEF.md and, for autonomous runs, prints the /goal line. Usage: /write-brief <slug> <rough description>"
agent: write
---

Request: $ARGUMENTS

Do not start writing. Load the `writing-genres` skill. Look at what exists in `research/` and `review/`. Then ask the user, in one round with the question tool, only what you cannot infer:

- genre (physics paper, mathematics paper, lecture notes, report), with your guess as the first option;
- venue and target reader, as concretely as possible ("PRB readers in correlated electrons", "second-year master's students who know quantum mechanics");
- length or page limit, and format (`.tex` or `.md`);
- the message in one sentence, offering your draft from the research as an option;
- for lecture notes: the reader's baseline (what the master's student already knows) and the project the notes prepare for;
- writing samples of theirs to learn their voice from (paths), if any;
- anything that must or must not be in it.

Write `writing/<slug>/BRIEF.md`. Then print, ready to paste:

`/goal Write writing/<slug> following its BRIEF.md with the write agent's procedure. The goal is met only when writing/<slug>/STATUS.md ends with "FINAL CHECK: PASS" and every ticked item names an existing file, or with "STATUS: BLOCKED" and what is missing.`
