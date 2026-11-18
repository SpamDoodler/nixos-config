---
name: Research goal brief
description: "How to write research/GOAL.md and the /goal line for an autonomous research run. Load when helping the user prepare a goal, or when a goal is vague."
---

# Writing a research goal for /goal

Abstract goals such as "Work out the relation between A and B" are fine; the team turns them into concrete formulations first. But under /goal nobody is there to answer questions, and the objective is capped at 4,000 characters. So the details go in `research/GOAL.md`, and the `/goal` line points to it and says what "done" means. `/brief` writes both with you, interactively, before the run starts.

## research/GOAL.md

```markdown
# Goal
Work out the relation between <A> and <B>.

## Where
<files or sections that define A and B>

## Why
<what the answer will be used for; this decides which formulation matters>

## Answer form
<e.g. "an explicit map, or an argument that none exists"; "the leading correction in g, with its range of validity">

## Rigor
P (physics) | M (mathematical) | L (Lean-certified); specify scope or claim-level overrides

## Known
<what you already know or suspect; dead ends you have hit>

## Budget
<e.g. at most 40 tasks and 4 astra attempts; stop and report if no formulation survives its spikes>

## Hand-off
<optional: "then write it up as a physics paper draft with the writer profile">
```

## The /goal line

```
/goal Carry out research/GOAL.md with the research agent's procedure. The goal is met only when research/STATUS.md ends with "GOAL CHECK: PASS" and every ticked item names an existing file, or with "STATUS: BLOCKED" and what would unblock it.
```

The completion rule is in the objective itself because the /goal reviewer re-reads the objective every round. A checkable rule turns "looks done" into "the file says so".

## What helps most, in order

1. **Why.** "Relation" has many meanings; the use you have in mind picks the right one.
2. **Answer form.** Tells the team when to stop.
3. **Where.** Saves the recon agents from guessing which A you mean.
4. **Known and dead ends.** Prevents re-solving.
5. **Budget.** /goal has no token budget of its own; this is the brake.

## Running it

1. Select the `research` agent. Run `/brief <rough idea>` and answer its questions; it writes `research/GOAL.md` and prints the /goal line.
2. Paste the line. In the first rounds, read the top of `research/STATUS.md` and `research/FRAMING.md`. If the interpretation is wrong: `/goal pause`, correct it in one message, `/goal resume`.
3. Use `/btw <question>` to ask about the run without adding to its history.
