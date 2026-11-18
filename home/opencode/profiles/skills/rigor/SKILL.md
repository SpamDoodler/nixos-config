---
name: Rigor levels
description: "Physics-level vs mathematical-level rigor: what counts as wrong, unproven-but-standard, or unverified; the evidence ladder. Load before judging any derivation or claim, and read examples.md in this skill's directory."
---

# Rigor levels for review

Every claim is checked at a **target rigor**.

- **P (physics level).** The default. The standard of a careful referee in the field: formal manipulations that specialists routinely use are fine, but the result must be right and must pass the physical sanity tests below.
- **M (mathematical level).** Only for claims the author marks as rigorous (theorem, proposition, lemma, "we prove", "rigorously"), or that the user marks M in the request.

## The central question

For every step that is not fully justified, decide which of three things it is. Only the first two are different from each other in a way that matters.

1. **Wrong.** The result differs from the correct one, or the step is invalid in this setting. This is a finding at any level.
2. **Unproven but standard.** Specialists use this step routinely and there is no reason to think it fails here. At level P this is **not a finding**. Record it in the rigor-notes table if it would matter at level M.
3. **Unverified.** You could not tell. Say so. Do not inflate it into a finding, and do not quietly call it fine.

**The referee test.** Would a competent referee in this specific subfield, reading at normal speed, ask for this to be fixed before publication? If not, it is at most a rigor note.

## Accepted without comment at level P

When the setting is a plausible one and no known obstruction applies:

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

Read the bundled `examples.md`. During document review also read `review/calibration.md` if present; `/calibrate` updates that workspace file. Examples guide classification, not whether evidence supports a result.
