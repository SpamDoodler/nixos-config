---
description: "Prepare an autonomous research run: clarify the goal with you, write research/GOAL.md, and print the /goal line to paste. Usage: /brief <rough idea>"
agent: research
---

Rough idea from the user: $ARGUMENTS

Do not start the research. Load the `research-goal` skill. Read enough of the workspace to understand the terms involved. Then ask the user, in one round with the question tool, only what you cannot infer: why they want the answer, what form a satisfying answer takes, the rigor level, what they already know or have tried, and the budget. Offer concrete choices where you can (for "relation between A and B", list the 3-4 most plausible kinds of relation as options).

Write `research/GOAL.md` from the skill's template, then print the /goal line from the skill, ready to paste. Finish with two lines: what you assumed, and what the user should check in the first rounds.
