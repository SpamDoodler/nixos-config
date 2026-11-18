# Literature audit

Keep the audit in `writing/<slug>/LITERATURE.md`. Start with the brief,
existing bibliography and research literature notes. Treat existing citations
as leads, not proof. Follow references and check authoritative versions or
primary sources for claims of attribution or overlap.

## Lecture notes: help the reader

- Use the intended baseline and prerequisite inventory. Find a few accessible
  references for the main concepts, methods and results a reader may want to
  revisit. Prefer a relevant chapter, section, theorem or worked example over
  a long undifferentiated reading list.
- Mark each reference as optional further reading or as a source for a result
  explicitly taken on trust. Explain what the reader will get from it. Do not
  outsource a prerequisite the notes promise to teach.
- Actively look for better expositions when the existing bibliography is
  aimed at specialists. Inspect the recommended passage or enough of the
  source to verify its content and level; metadata alone does not verify a
  reading recommendation. For each selected reading, provide the locator,
  audience or prerequisites, and a one-sentence reason to read it.
- Put a short, annotated **Further reading** section in the notes (at the
  end of the relevant chapters or in one section grouped by topic). Tie each
  recommendation to something already taught. It is optional enrichment,
  not a replacement for citations in the text or for teaching promised material.

## Papers: establish the boundary, give credit

- Compare the main results with the closest prior work: exact statement,
  hypotheses, regime, method, and overlap where material. Distinguish
  established, reproduced, adapted and extended results. Verify attribution
  for reused results, methods and conventions; cite original work where
  appropriate and later expositions where they help. Flag independent,
  equivalent, or concurrent work when verified.
- Keep the detailed comparison internal. In the paper, use concise context
  and cite where the relevant result or method is used. Explain the distinction
  only where needed to understand the contribution or avoid misattribution.
  Do not repeat novelty claims or add a novelty section by default. A bounded
  search cannot establish priority; if the boundary remains uncertain, use
  narrow, factual wording and avoid unsupported “first” or “new” claims.

## Audit record and final checks

For each retained reference record authors, title, year, stable link or
identifier, precise locator if available, what was actually inspected
(metadata, abstract, or relevant text), what it supports, and where to cite
it or recommend it to the reader. Separate unverified leads and state
important coverage gaps. Do not invent citations, infer theorem conditions
from abstracts, or present an unread source as checked.

Hand off each selected source with its existing or proposed citation key
and enough verified bibliographic data to make a real entry. The drafter
cites borrowed results, methods, and other material sourced claims where
they are used, including results taken on trust in the notes. Use the
project's citation system: for LaTeX, use citation commands tied to real
bibliography entries; for Markdown without a citation processor, use inline
references or footnotes that resolve to a full reference or stable source.
Further-reading entries should also resolve to full references. Internal
audit paths and `[CITE: …]` placeholders are not citations.

Before finalizing, verify that each material citation supports its use and
resolves to an actual bibliography entry. For lecture notes, check that
recommendations suit the baseline and say why they help. For papers, check
that credit is visible and novelty wording is accurate and proportionate.
If a material attribution cannot be verified, narrow or remove the affected
claim where possible; otherwise mark the audit open and report the blocker.
