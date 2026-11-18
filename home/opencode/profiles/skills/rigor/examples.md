# Rigor calibration examples

These are regression cases for applying the rubric in `SKILL.md`, not sources of policy or proof. If a case conflicts with a claim's obligations, flag the conflict and apply the rubric. Use `/calibrate` for additional workspace cases.

Format: **Situation** / **Decision** / **Why**.

---

**Situation.** Eq. (7) exchanges a sum over modes with an integral over time. Each mode is smooth and decays exponentially after Wick rotation, but there is no bound on the sum over modes.
**Decision.** GAP if the exact identity depends on the exchange and gives no justification. A summable bound in integrable norm, or another applicable argument, could close it.
**Why.** Decay of individual modes does not control the sum.

---

**Situation.** The expansion in coupling g is truncated at first order with no estimate of the second-order term. The application in Sec. 5 uses g = 0.7.
**Decision.** Finding: APPROX, severity MAJOR if the Sec. 5 result is load-bearing.
**Why.** The small parameter is not small where the result is applied. Missing rigor is not the issue; the answer may be wrong.

---

**Situation.** A boundary term is dropped after integration by parts. The field falls off as 1/r in three dimensions.
**Decision.** Finding: probable WRONG.
**Why.** The surface area grows as r², so the boundary term does not vanish.

---

**Situation.** An exact result uses a squared delta function without defining the product. It agrees with a known special case and a numerical check.
**Decision.** GAP if the product carries the identity. Specify the formal setting or a regulator and justify the operation or limit there.
**Why.** Agreement in checks is useful evidence but does not define the product.

---

**Situation.** A factor 2π is missing between Eq. (3) and Eq. (4). Eq. (9) onward uses the corrected normalisation.
**Decision.** NIT or MINOR if nothing downstream used the wrong version. MAJOR if a numerical result was computed from Eq. (4).
**Why.** Severity follows whether the error propagates, not how obvious it is.
