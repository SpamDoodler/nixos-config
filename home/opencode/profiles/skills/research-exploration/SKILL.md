---
name: Research exploration
description: "Use with /explore for open problems. Run a bounded portfolio of distinct approaches, compare discriminating tests, park blocked routes, and combine usable results."
---

# Explore an open problem

This mode chooses **which approaches to pursue**. The normal
`research-procedure` still governs framing, pre-mortem, ledger dispatch,
verification and reporting. A route is an approach, not a worker attempt.
Use separate ledger tasks for independent tests; `ledger dispatch routes=N`
means competing attempts at one card and is not the portfolio mechanism.

## Frame and start

1. Read the goal, `research/ROUTES.md` if present, and the relevant research
   plan, ledger, decisions and negative results. Reuse compatible findings.
   On resume, reconcile outstanding task IDs with the ledger and continue the
   last unfinished round. If the request would replace an active, unrelated
   goal or portfolio, ask before changing it.
2. State what would count as progress or a solution and the assumptions that
   matter. Start with up to three materially different routes. Prefer
   different mechanisms, assumptions or evidence sources: e.g. an exact
   reduction, a constructive special case, and an obstruction search.
   For each, name one cheap decisive test, what outcome would change your
   decision, and when to park or drop it. Do not pad the portfolio with
   duplicates if fewer routes make sense.
3. Record the portfolio in `research/ROUTES.md`; see `route-map.md`. In the
   absence of user limits, allow at most **three active routes, five distinct
   routes admitted, eight new exploration task cards, and three rounds**.
   These are limits across the run, not per turn or per route. Ledger retries,
   verifiers and automatic probes are additional model calls; respect any
   user-supplied allowance, time, or call cap separately. Do not silently
   extend the run or start native `/goal`.
4. Use the normal pre-mortem before first dispatch. Register the first cheap
   tests with the ledger, linking each card to its route ID. Dispatch
   independent tests together within the ledger's free slots. End your turn
   while workers run; process their reports when they arrive. Do not count
   an interrupted or partially completed batch as a fresh round.

## Decide at the end of each batch

Compare the tests against their predicted outcomes and update the map:

- **Continue** when there is specific new evidence or a sharper, actionable
  test. State what the next task could settle. Keep a contrasting route
  alive where it could falsify the apparent leader.
- **Park** when a named dependency, clarification, or better test is missing.
  Record the condition for reopening. A worker timeout or model failure
  is not evidence that the approach is impossible.
- **Drop** for a concrete obstruction, duplicate mechanism, or unfavorable
  cost versus information gain. State which reason applies. Record verified
  negative results in `research/negative-results.md`; label unverified
  obstacles as such.
- **Open** a new route only when a distinct idea addresses an uncovered
  possibility, leverages a new result, or offers a more informative test
  than the weakest active route. Stay within the remaining budget.
- **Connect** routes when one provides a lemma, witness, counterexample, or
  tool another can use. Record the direction and supporting task IDs.
  **Merge** only after checking assumptions, domains and conventions; name
  a bridge task if compatibility is uncertain. Preserve both source routes
  and their provenance. Do not count reused evidence as replication.

Record what changed, why, and the most informative next test before opening
or dispatching more cards. Update the normal research decisions log if this
changes the frozen plan. Record the round with `ledger status`, including
`active_routes` (IDs and current tests), `focus`, `changed`, `blockers` and
`next` as relevant. Tell the user what is being tested and why any route was
opened, dropped, parked, or merged; don't just list IDs. The route map
is a decision record, not a duplicate of ledger task status.

## Stop or hand off

Stop opening tasks when a promising route has a precise claim or proof plan
to verify, no remaining test is worth its cost, or the budget is reached.
Finish or explicitly account for in-flight checks. Do not automatically
start a deeper phase outside the agreed scope. A promising claim goes through
the usual research verification, including the required independent checks,
before it goes into `CLAIMS.md` as verified.

Report the strongest direction, what was ruled out and on what evidence,
what remains open, budget used, and the next discriminating test. If using
`/goal` separately, apply the usual goal-mode rules as well. Reload this skill
and the saved route map after compaction.
