# Style examples: before and after

Each example shows a habit and a fix. The first ones are generic seeds. Add your own with `/style-note`; examples from your field and your own revisions teach the writer more than any rule. Where an example and SKILL.md disagree, the example wins.

Format: **Before** / **After** / **Why**.

---

**Before.** In today's rapidly evolving landscape of condensed matter physics, topological superconductors play a crucial role and have attracted significant attention.
**After.** A topological superconductor would host Majorana modes at its edges, but every candidate material so far needs a magnetic field that also suppresses the gap.
**Why.** The first version could open any paper in the field. The second gives the reader the problem this paper addresses.

---

**Before.** It is important to note that these results may potentially suggest that the coupling could play a role.
**After.** The decay rate grows with the coupling, roughly as g² for g < 0.3 (Fig. 2).
**Why.** Throat-clearing plus four hedges. The fix states what was found and where it holds.

---

**Before.** Let Δ(k) = Δ₀ tanh(kξ), where Δ₀ is the gap, ξ the coherence length and k the momentum.
**After.** We need a gap that grows linearly at small momentum and saturates at large momentum, because a gap that vanishes too fast leaves the winding number undefined. The simplest such profile is Δ(k) = Δ₀ tanh(kξ), with Δ₀ the bulk gap and ξ the coherence length.
**Why.** The reader learns why this form, before learning which form.

---

**Before.** In this section, we will present our numerical results. The results are shown in Fig. 3. As can be seen, the agreement is excellent.
**After.** The numerics agree with the analytic result to within 2% for all couplings below 0.5 (Fig. 3); above that, the analytic curve undershoots because the next order is no longer small.
**Why.** Announcement, pointer and a judgement replaced by the actual comparison, with its limit.

---

**Before.** Moreover, the method is robust. Furthermore, it is efficient. Additionally, it generalises to higher dimensions.
**After.** The method converges for every initial condition we tried, takes seconds per point, and needs no change in three dimensions except a larger grid.
**Why.** Three decorative transitions and three vague adjectives replaced by three checkable facts in one sentence.

---

**Before (math).** We now prove the main theorem. The proof is quite technical and may be skipped on first reading.
**After (math).** The proof has two steps. We first bound the error on each cell by the local oscillation (Lemma 3.2), then sum the bounds using the covering of Lemma 2.4. Only the second step uses the regularity assumption.
**Why.** The reader gets the shape of the proof and where the hypothesis enters, which is what lets them check it.

---

**Before (lecture notes).** Definition 4.1. A connection on a vector bundle E is a linear map ∇ : Γ(E) → Γ(T*M ⊗ E) satisfying the Leibniz rule.
**After (lecture notes).** On a curved surface we cannot compare vectors at different points directly: "the same direction" has no meaning until we choose how to carry a vector along a path. A connection is that choice, written as a rule for differentiating sections. [Then the definition, then the example of the sphere.]
**Why.** In teaching, the reason for a definition matters more than its formal statement, and an example right after it makes it stick.
