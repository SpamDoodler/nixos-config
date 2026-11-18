# Mathematics paper

**Purpose.** State precise results and prove them so that a specialist can check every step, while showing why the results are interesting and how the proofs work. The reader asks: what exactly is proved? Under which hypotheses? Is it new? How does the proof go, and where is the hard part?

## Structure

1. **Title.** Names the objects and the result. "Spectral gaps for random Schrodinger operators on trees" rather than "Some remarks on spectral theory".
2. **Abstract.** The main result in words, with the key hypothesis, and what it improves on.
3. **Introduction.**
   - Context: the question and its history, through the results that matter, with exact references.
   - **The main theorem, stated early.** First informally, then exactly (Theorem 1.1), with every hypothesis.
   - What is new: which hypothesis is weakened, which bound improved, which case first handled.
   - Idea of the proof: a paragraph on the strategy and where the difficulty lies.
   - Organisation, briefly.
4. **Preliminaries and notation.** Only what is used. A notation section is acceptable here, but motivate non-standard definitions.
5. **Body.** Definition, lemma, proposition, theorem, proof. Long proofs open with a sketch. Say in remarks why a hypothesis is needed, and give an example showing it cannot simply be dropped.
6. **Further directions and open problems.** Optional; precise conjectures are welcome if labelled as such.

## Tone and level of detail

- Mathematical-level rigor: every result labelled Theorem, Proposition, Lemma or Corollary is proved in full or cited with the exact statement and its conditions. Check the evidence level in `EVIDENCE.md`. A result supported only at physics level becomes a Conjecture or a "formal computation", explicitly labelled. This check is not optional.
- Hedging nearly vanishes. A statement is proved, conjectured (labelled) or not made. "It seems that" and "we believe" belong in remarks about conjectures, never in a proved statement.
- Motivation is mathematical: why the question is natural, hard and worth solving. Physical motivation, if any, is brief and in the introduction.
- Examples and counterexamples are the best motivation for definitions and hypotheses.
- Economy matters. A computation the reader can easily do is left to them, but say that it is easy and what it uses. A step that took you a day is not "easy".
- Quantifiers explicit. Constants: say what they depend on.
- Standard phrases ("we may assume", "it suffices to show", "without loss of generality") are fine. They are precise, not hedges.

## Common failures

- The main theorem appears on page 8.
- Definitions with no example and no reason.
- "Clearly" and "it is easy to see" hiding the hardest step.
- Physics-level arguments presented as proofs.
- Remarks that repeat the theorem instead of explaining it.
