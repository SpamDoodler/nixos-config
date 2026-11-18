---
name: Writing style
description: "House style for technical writing: lead with the point, motivate before defining, words before symbols, hedges set by the evidence and nothing else, and the habits that make text sound machine-written. Load before drafting, editing or judging prose. Read examples.md in this skill's directory too."
---

# Writing style

The reader is an expert in a hurry. Every sentence should either tell them something or get them ready for the next thing that does. Most "AI sound" comes from text that does neither. It announces, qualifies, summarises and praises instead of saying.

Read the bundled `examples.md` and any workspace `writing/style-notes.md`. User style notes take precedence over generic examples, but never over the evidence.

## 1. Say the thing

- **Lead with the point.** First sentence of the abstract: the result. First sentence of a section: what the section establishes. First sentence of a paragraph: the claim the paragraph supports.
- **Be specific.** "The gap closes at g = 0.31" beats "the gap exhibits interesting behaviour". A number, a condition, a name or a mechanism beats an adjective.
- **No announcements.** Delete "In this section we will", "It is worth noting that", "As mentioned above". If the sentence after the announcement is good, it does not need the announcement.
- **No ceremonial summaries.** Do not end sections by restating them, or close with a moral ("This demonstrates the power of..."). A summary belongs where a reader needs it: the abstract, the conclusion, the end of a long chapter.
- **No self-praise.** Remove "novel", "elegant", "remarkable", "powerful", "striking". If the result is remarkable, the reader will notice.
- **No stock words.** delve, crucial, pivotal, landscape, realm, leverage, harness, robust (unless it is the technical term), seamless, underscore, showcase, foster, comprehensive, shed light on, pave the way, plays a key role, a testament to. Each has a plain replacement or should go.

## 2. Motivate before you define

- Before a definition, give the problem it solves or the question it answers. A definition with no visible purpose is the most common reason readers stop.
- Before a long computation, say what it will produce and why we want it. After it, say what it means.
- Each section opens by connecting to the reader's question: why do they need this now?
- Motivation is specific to this result. "X is of fundamental importance in modern physics" motivates nothing; "without X we cannot predict the decay rate measured in Ref. 4" does.

## 3. Words before symbols

- Introduce a quantity in words, then name it: "the energy needed to break a pair, Δ".
- Give a symbol only to something used at least three times or that appears in a displayed equation.
- Never start a sentence with a symbol.
- After an equation, say in words what it tells us: the dependence, the sign, the limit, the size.
- Keep the symbol count small. The reader has to hold each symbol in memory. Ten new symbols on one page is a wall.
- Follow the project's conventions file (`research/CONVENTIONS.md` or the brief). One meaning per symbol throughout the document.
- No symbols in the abstract unless the result cannot be stated without one.

## 4. Hedges come from the evidence, not from habit

Every claim gets exactly the confidence the evidence supports, stated once.

| Evidence (from EVIDENCE.md) | How to write it | Example |
| --- | --- | --- |
| Derived and independently checked (levels 1-2) | Plain statement | "The correction is negative for all g < 1." |
| Checked once, by one method (level 3) | Name the method | "Our numerics give a negative correction for all g we sampled (0.05 to 0.9)." |
| Conjecture or extrapolation (levels 4-5) | Label it, give the reason | "We conjecture that the sign persists at strong coupling, because ..." |
| Known limitation | State the boundary | "The expansion fails once g approaches 1, where the next term is as large as the first." |
| Refuted, or a negative result | Plain statement | "The two quantities are not related by a local map: ..." |

Rules:

- One hedge per claim at most. Never stack ("may potentially suggest").
- Replace a vague hedge with its content: the condition, the range, the error bar, or the missing check.
- Do not hedge what is proven. Do not state firmly what is not.
- "We" is fine and usually clearer than the passive.

## 5. Paragraphs and sentences

- One idea per paragraph. The first sentence states it; the rest support it.
- Old information first, new information last. Each sentence starts from something the reader already has and ends on the new point, which is where emphasis falls.
- Keep the subject and its verb close together, near the start of the sentence.
- Vary length. Uniform paragraphs and sentences of identical rhythm read as generated. Short sentences are good for results; longer ones for reasoning that has to stay together.
- Name things instead of "this": "This shows" becomes "The sign change shows".
- Transitions should carry logic ("because", "so", "but", "unlike the free case"), not decoration ("Moreover", "Furthermore", "Additionally").
- Use lists only for genuinely parallel items: assumptions, steps of an algorithm, conditions. An argument is prose.
- Em dashes rarely. Commas, parentheses or a full stop usually work better.

## 6. Equations and figures

- An equation is part of a sentence and is punctuated as one.
- Display an equation only if it is referred to later or is a result the reader should see. Number only those you refer to.
- Each figure has one message, and the caption states it in its first sentence ("The gap closes linearly at g_c."), then says what is plotted.
- Axes labelled with quantity and unit. Same quantity, same colour and symbol across figures.
- Text and figure must agree on numbers.

## 7. Before you hand text over

- Run the `stylecheck` tool for the document's genre and read the flags.
- Read the first sentence of every paragraph in order. They should tell the story on their own. If they do not, the structure is wrong, and no amount of sentence editing will fix it.
- Check that every claim is in `EVIDENCE.md` at the strength you wrote it.
