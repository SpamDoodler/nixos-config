# Review benchmark

Two sources of data, both logged with the `bench` tool and reported by `bench review_report`.

## In every review

- `rv_check` for each checker run: which role, which model, which claims it examined.
- `rv_findings` for each candidate after triage: confirmed, downgraded, rejected or duplicate; later with its origin.
- `outcome type=gap-resolution` for each resolution attempt, with the checker's verdict.

From these the report computes, per role and model: **precision** (share of its candidates you kept), **relative recall** (of confirmed findings on claims it examined, the share it raised), and the **resolution rate** per model. Relative recall has a blind spot: an error nobody found counts against nobody. Planted reviews fix that.

## Blind re-derivation calibration

Register each tier's run with `rv_check role=derive task_id=<shared-id> difficulty=<1–5> rigor=P|M` before seeing results. After checking the saved blind work against a validated reference, record `rv_derive review=<slug> check_id=<run> derive_result=solved|incorrect|unresolved|ungraded`. `solved` requires a complete independent derivation at the stated rigor, not a matching final expression. `incorrect` is a completed but wrong derivation; `unresolved` includes partial attempts and budget limits; `ungraded` means there is no reliable reference yet (or the blind attempt is contaminated). Never assume the manuscript is right.

The report groups attempts by the pre-run rating and rigor, separately from finding recall. Pending and ungraded runs are not evidence of failure. The cheapest verified success is evidence for this setup and budget, not proof that it is the minimum capable tier. Keep this calibration separate from novel research routing.

## Planted-error reviews (`/review-bench`)

1. `rv-planter` takes a document you trust, plants errors of known kinds (a sign flip in a load-bearing step, a missing factor that propagates, a dropped same-order term, a swapped limit order, an approximation outside its regime, a misquoted citation) plus **traps**: steps that look sloppy but are fine at physics level. It writes the planted version to `review/<slug>/target/` and the answer key to `review/<slug>/bench/`, which no reviewer can read.
2. The review runs normally on the target. Do not look for the key.
3. After `REPORT.md`, launch `rv-scorer`. It reads the key, your findings and the check reports, and logs `rv_planted` and `rv_matches`: for each planted item and each check that examined its claim, whether that check found it. Flagging a trap is a false positive.

This gives true recall per role and model, and a false-positive rate on traps, which is the direct measure of whether a model understands that physics-level rigor is fine.
