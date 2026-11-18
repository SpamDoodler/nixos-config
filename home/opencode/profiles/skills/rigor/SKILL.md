---
name: Rigor levels
description: "Choose claim-specific obligations using physics (P), mathematical (M), or Lean-certified (L) rigor."
---

# Rigor levels for review

Every claim has a **target rigor** and concrete **obligations**. P, M and L are
starting points, not substitutes for spelling out what the claim promises.

- **P (physics level).** The default. The standard of a careful referee in the field: formal manipulations that specialists routinely use are fine, but the result must be right and must pass the physical sanity tests below.
- **M (mathematical level).** Use for claims presented as rigorous (e.g. theorem, proposition, lemma, "we prove") or marked M by the user.
- **L (Lean-certified level).** Select explicitly for a scope or claim. In that scope every substantive claim needs a matching Lean certificate; a rigorous prose proof alone is not sufficient. Read `lean-certificates.md` before planning, checking, or reporting L claims.

## Set obligations before checking

State the claim's scope, assumptions, and the specific conditions that would
make it stand as written. Apply the user's explicit standard or obligation
override to the named claim, and record its scope. Relaxing a review
requirement does not turn missing evidence into a proof or silently weaken
what the manuscript asserts. Mark ambiguous scope instead of choosing the
easier reading silently.

| Claim as stated | Typical obligations |
| --- | --- |
| Formal identity | Specify the algebra or formal expansion, the coefficient domain, and why the coefficient operations and any rearrangements are defined. Require analytic convergence only if an analytic equality is also claimed. |
| Controlled approximation | State the regime, small parameter, and why omitted terms are subleading in that regime. Require an explicit bound if promised, or if needed to support a quantitative conclusion. |
| Exact analytic identity | Specify domains and hypotheses. Justify the load-bearing steps, such as exchanging limits, taking boundary values, choosing branches or contours, and treating poles. Exactness can impose these obligations at P too. |
| Numerical observation | Record enough inputs, method, and precision to reproduce it. Check relevant resolution, parameter sensitivity, and error sources. Do not infer a proof from finite tests. |

Use applicable field references to justify a standard move when it carries
the claim: check the statement and conditions, not merely the citation.
Record separately the obligation, the evidence for it, and whether it is
met, unmet, or unresolved. Severity follows what depends on it. A blind
re-derivation that repeats an unjustified operation can corroborate the
algebra, but does not establish the conditions for that operation.

## The central question

For every step that is not fully justified, decide which of three things it is. Only the first two are different from each other in a way that matters.

1. **Wrong.** The result differs from the correct one, or the step is invalid in this setting. This is a finding at any level.
2. **Unproven but standard.** This is a note at P only if the missing justification is not an obligation of the claim as stated. It cannot substitute for an L certificate.
3. **Unverified.** You could not tell. Say so. Do not inflate it into a finding, and do not quietly call it fine.

**The referee test.** Would a competent referee in this specific subfield, reading at normal speed, ask for this to be fixed before publication? If not, it is at most a rigor note.

## Often acceptable at P when not an unmet claim obligation

These are common shortcuts, not blanket permission. If a result materially
depends on one, state why it applies here; mark it unresolved if that cannot
be checked. A smooth integrand alone does not justify exchanging a sum and
an integral.

- Exchanging sums, integrals, derivatives and limits for smooth, decaying integrands.
- Dropping boundary or surface terms when the fields fall off fast enough physically.
- Perturbative and asymptotic expansions truncated without remainder bounds, provided the small parameter is identified, is small in the regime used, and the next term is estimated or plausibly smaller.
- Distributions and formal objects used the standard way: delta functions, formal Gaussian and Fresnel integrals, Wick rotation, analytic continuation, regularised sums.
- Existence, uniqueness and regularity of solutions assumed where physically sensible.
- Heuristic arguments that get the scaling and structure right.
- Leaving out measure theory, function-space and operator-domain details.

## Still required at level P (missing or failing any of these is a finding)

1. Dimensional and unit consistency.
2. Correct limiting cases; known special cases recovered.
3. Symmetries, conservation laws, sum rules and Ward identities respected.
4. Approximations: the small parameter is named, it is actually small where the result is applied, and neglected terms are estimated.
5. Signs, factors of 2, 2π, 4π, and normalisations consistent with the stated conventions.
6. No hidden divergences: UV or IR divergences, zero modes, secular terms, resonances are handled or argued absent.
7. If the order of two limits matters, it is stated and justified.
8. Orders of magnitude are plausible; numerics converge with resolution and step size.
9. No circularity; no assumption smuggled in.
10. Claims of exactness or universality are argued, not asserted.

## Red flags: "non-rigorous" becomes "probably wrong"

- Interchanging limits or sums with integrals when the integral is only conditionally convergent, or the convergence is not uniform.
- Applying a perturbative series where non-perturbative effects are of the same order, or beyond its range of validity.
- Dropping a term of the same order as the terms kept.
- Boundary terms that do not vanish: slowly decaying fields, topological terms, anomalies.
- Non-uniform asymptotics; results that depend on the regulator.
- Dividing by something that can vanish; passing through a branch cut or pole in analytic continuation.
- An exact result that fails a special case it should reproduce.

## Level M

For claims marked M: hypotheses and quantifiers stated; domains specified; each step justified; existence, convergence and uniqueness proven or cited with the exact statement; error bounds explicit; no "it can be shown" without a reference or a proof.

## Rigor notes

A step that is fine at P but would not pass at M goes in the rigor-notes table, not in the findings:

`location | what M would need (e.g. "uniform convergence of the series on [a,b]") | routine / hard / open`

It does not count toward severity. The author can promote any of them later.

## Evidence ladder

Say which level supports every "verified":

1. Independently re-derived, blind.
2. Numerically verified against an independent computation.
3. Limits, symmetries or special cases checked.
4. Matches a cited result whose exact statement and conditions were checked.
5. Internally consistent but not otherwise checked.
6. Asserted by the author.

## Calibration

Use bundled `examples.md` and, during document review, `review/calibration.md`
if present as regression cases for consistent judgments. They do not set the
standard, override the rubric or user-scoped obligations, or supply evidence.
If an example conflicts with the applicable rule, flag the conflict and
apply the rule. `/calibrate` records examples, not policy changes.
