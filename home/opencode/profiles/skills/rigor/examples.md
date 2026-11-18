# Rigor calibration examples

These teach the reviewer what counts as acceptable, a finding, or a note in YOUR field. The first five are generic seeds. Replace them with real cases from your own papers and referee reports; use `/calibrate` to add new ones as you disagree with a review. Examples outrank the rubric in SKILL.md.

Format: **Situation** / **Decision** / **Why**.

---

**Situation.** Eq. (7) exchanges a sum over modes with an integral over time. The integrand is smooth and decays exponentially after Wick rotation.
**Decision.** Fine at P. Rigor note (routine) if the target were M.
**Why.** Standard move, no obstruction visible, specialists do it without comment.

---

**Situation.** The expansion in coupling g is truncated at first order with no estimate of the second-order term. The application in Sec. 5 uses g = 0.7.
**Decision.** Finding: APPROX, severity MAJOR if the Sec. 5 result is load-bearing.
**Why.** The small parameter is not small where the result is applied. Missing rigor is not the issue; the answer may be wrong.

---

**Situation.** A boundary term is dropped after integration by parts. The field falls off as 1/r in three dimensions.
**Decision.** Finding: probable WRONG.
**Why.** The surface area grows as r², so the boundary term does not vanish.

---

**Situation.** A formal manipulation with a squared delta function. The result agrees with a known special case and with the numerical check in Fig. 3.
**Decision.** Rigor note only.
**Why.** Formal but standard, and the independent checks pass.

---

**Situation.** A factor 2π is missing between Eq. (3) and Eq. (4). Eq. (9) onward uses the corrected normalisation.
**Decision.** NIT or MINOR if nothing downstream used the wrong version. MAJOR if a numerical result was computed from Eq. (4).
**Why.** Severity follows whether the error propagates, not how obvious it is.
