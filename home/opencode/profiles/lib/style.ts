// Deterministic prose checks for the writer profile. Works on Markdown and LaTeX.
// It measures habits, not quality: a clean report is necessary, not sufficient.

export type Genre = "physics-paper" | "math-paper" | "lecture-notes" | "report"

interface Limits {
  hedgesPer1k: number
  mathPer100: number
  meanSentence: number
  longShare: number // share of sentences over 35 words
  transitionsPer1k: number
  emDashPer1k: number
  bulletShare: number
  stockMax: number // stock phrases allowed before FAIL
  artifactRefs: "forbid" | "tolerate" | "allow" // references to research/review/writing files, task or claim ids, agents
}
export const LIMITS: Record<Genre, Limits> = {
  "physics-paper": { hedgesPer1k: 6, mathPer100: 8, meanSentence: 26, longShare: 0.15, transitionsPer1k: 3, emDashPer1k: 3, bulletShare: 0.05, stockMax: 2, artifactRefs: "forbid" },
  "math-paper": { hedgesPer1k: 3, mathPer100: 14, meanSentence: 28, longShare: 0.2, transitionsPer1k: 3, emDashPer1k: 2, bulletShare: 0.05, stockMax: 2, artifactRefs: "forbid" },
  "lecture-notes": { hedgesPer1k: 5, mathPer100: 8, meanSentence: 22, longShare: 0.1, transitionsPer1k: 4, emDashPer1k: 3, bulletShare: 0.15, stockMax: 3, artifactRefs: "tolerate" },
  report: { hedgesPer1k: 5, mathPer100: 3, meanSentence: 22, longShare: 0.1, transitionsPer1k: 3, emDashPer1k: 3, bulletShare: 0.3, stockMax: 2, artifactRefs: "allow" },
}

const HEDGES = [
  "may", "might", "could", "possibly", "potentially", "perhaps", "probably", "likely", "arguably", "somewhat",
  "relatively", "fairly", "rather", "quite", "generally", "typically", "seems?", "seemed", "appears? to", "appeared to",
  "suggests?", "suggested", "tends? to", "to some extent", "to a certain degree", "in some sense", "it is possible that",
  "it is likely that", "one could argue", "in principle",
]
// "we may assume", "one may check": standard mathematical usage, not a hedge.
const HEDGE_EXEMPT = /\b(we|one|you|they) (may|might|could)\b/gi

const STOCK: [RegExp, string][] = [
  [/\bdelv(e|es|ing)\b/gi, "stock word"], [/\btapestry\b/gi, "stock word"], [/\bintricac(y|ies)\b|\bintricate\b/gi, "stock word"],
  [/\bpivotal\b/gi, "stock word"], [/\bcrucial(ly)?\b/gi, "stock word: say why it matters instead"], [/\bparamount\b/gi, "stock word"],
  [/\blandscape\b/gi, "stock word"], [/\brealm\b/gi, "stock word"], [/\bleverag(e|es|ed|ing)\b/gi, "stock word: say 'use'"],
  [/\bharness(es|ed|ing)?\b/gi, "stock word: say 'use'"], [/\bseamless(ly)?\b/gi, "stock word"], [/\bshowcas(e|es|ed|ing)\b/gi, "stock word"],
  [/\bunderscor(e|es|ed|ing)\b/gi, "stock word"], [/\bfoster(s|ed|ing)?\b/gi, "stock word"], [/\bmultifaceted\b/gi, "stock word"],
  [/\bnuanced\b/gi, "stock word"], [/\bholistic\b/gi, "stock word"], [/\bcomprehensive\b/gi, "stock word: say what is covered"],
  [/\bgroundbreaking\b|\bcutting-edge\b|\bunprecedented\b|\brevolutioni[sz]e\b|\bgame-changer\b|\bparadigm shift\b/gi, "hype"],
  [/\bsheds? light on\b/gi, "stock phrase: say what is found"], [/\bpaves? the way\b/gi, "stock phrase"],
  [/\bplays? an? (crucial|pivotal|key|important|central|fundamental|vital) role\b/gi, "stock phrase: say what it does"],
  [/\bit is (important|worth|crucial) (to note|noting|mentioning)\b|\bit should be noted\b|\bworth mentioning\b/gi, "throat-clearing: just say it"],
  [/\ba testament to\b|\bstands as\b|\bserves as an? (reminder|testament|example|foundation)\b/gi, "stock phrase"],
  [/\bin the realm of\b|\bnavigat(e|es|ing) the\b|\bever-evolving\b|\brapidly evolving\b|\bin today's\b/gi, "stock phrase"],
  [/\bnot only\b[^.]{0,80}\bbut also\b/gi, "'not only ... but also' construction"], [/\bat its core\b|\bkey insight\b|\bdeep dive\b|\bembark\b/gi, "stock phrase"],
  [/\b(elegant|remarkabl[ey]|strikingly?|profound(ly)?|powerful|beautiful)\b/gi, "self-praise: let the result speak"],
  [/\bnovel\b/gi, "'novel': say what is new"],
]
const SIGNPOST = /\b(in this (section|chapter|paper|work|note),? we (will|shall)|we (will|shall) now|in what follows|as (we will|we shall) see|as (mentioned|discussed|noted) (above|earlier|before|previously)|the rest of (this|the) (paper|section) is organi[sz]ed)\b/gi
// Traces of the research process that a self-contained paper must not show.
const ARTIFACT = /\b(research|review|writing)\/[\w./<>-]*|\btasks?\/?T\d+\b|\bT\d{3}\b|\bclaim C\d+\b|\b(LEDGER|CLAIMS|EVIDENCE|FRAMING|STORY|BRIEF|PLAN|STATUS|GOAL|CONVENTIONS)\.md\b|\b[\w-]+\.(jsonl|ipynb)\b|\b(verifier|subagent|orchestrator|task card|the ledger)\b|\b(luna|terra|astra)\b|\bevidence level\b/gi
const PLACEHOLDER = /\[(CLAIM NEEDED|CITE)[^\]]*\]/g
const TRANSITION_START = /^(moreover|furthermore|additionally|in addition|notably|importantly|crucially|overall|ultimately|interestingly|indeed|in summary|in conclusion|to summari[sz]e)\b/i
const VAGUE_THIS = /^(this|these|that) (is|are|was|shows?|means|allows?|implies|leads|gives|suggests?|demonstrates?|highlights?|makes|yields|indicates?|enables?)\b/i

export interface Sentence { line: number; text: string; words: number }
export interface Flag { line: number; reason: string; excerpt: string }

/** Replace removed spans by spaces of the same length, so line numbers survive. */
const blank = (m: string, token = "") => {
  const nl = m.replace(/[^\n]/g, "")
  return (token ? ` ${token} ` : " ") + nl
}

export function toProse(src: string, kind: "md" | "tex") {
  let t = src
  let displays = 0
  let inline = 0
  if (kind === "tex") {
    t = t.replace(/(^|[^\\])%.*$/gm, (m, p) => p)
    const head = t.indexOf("\\begin{document}")
    if (head >= 0) t = t.slice(0, head).replace(/[^\n]/g, "") + t.slice(head)
    t = t.replace(/\\begin\{(equation|align|gather|multline|eqnarray|displaymath|split|alignat|flalign)\*?\}[\s\S]*?\\end\{\1\*?\}/g, (m) => (displays++, blank(m, "MATH")))
    t = t.replace(/\\\[[\s\S]*?\\\]|\$\$[\s\S]*?\$\$/g, (m) => (displays++, blank(m, "MATH")))
    t = t.replace(/\\\([\s\S]*?\\\)|\$[^$\n]+\$/g, (m) => (inline++, blank(m, "MATH")))
    t = t.replace(/\\begin\{(figure|table|tikzpicture|tabular)\*?\}[\s\S]*?\\end\{\1\*?\}/g, (m) => {
      const cap = /\\caption\{([^}]*)\}/.exec(m)
      return cap ? cap[1] + ". " + m.replace(/[^\n]/g, "").slice(0, -1) : blank(m)
    })
    t = t.replace(/\\(cite[a-z]*|ref|eqref|cref|Cref|autoref|label|url|href)\*?(\[[^\]]*\])*\{[^}]*\}/g, (m, c) => (c === "label" ? "" : " REF "))
    t = t.replace(/\\(section|subsection|subsubsection|chapter|paragraph|title)\*?\{([^}]*)\}/g, (_m, _c, x) => `\n\n#HEAD ${x}\n\n`)
    t = t.replace(/\\item\b/g, "\n- ")
    t = t.replace(/\\(begin|end)\{[^}]*\}(\[[^\]]*\])?/g, "\n")
    t = t.replace(/---/g, "—")
    t = t.replace(/\\[a-zA-Z]+\*?(\[[^\]]*\])?/g, "").replace(/[{}~]/g, (c) => (c === "~" ? " " : ""))
  } else {
    t = t.replace(/^```[\s\S]*?^```/gm, (m) => blank(m))
    t = t.replace(/\$\$[\s\S]*?\$\$/g, (m) => (displays++, blank(m, "MATH")))
    t = t.replace(/\$[^$\n]+\$/g, (m) => (inline++, blank(m, "MATH")))
    t = t.replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
    t = t.replace(/^\|.*$/gm, "")
    t = t.replace(/^(#{1,6})\s+(.*)$/gm, "#HEAD $2")
    t = t.replace(/^\s*(\d+\.|[-*+])\s+/gm, "- ")
    t = t.replace(/[*_`]/g, "")
  }
  return { text: t, displays, inline }
}

const ABBR = /\b(e\.g|i\.e|et al|Eq|Eqs|Fig|Figs|Ref|Refs|Sec|Secs|cf|vs|Thm|Prop|Lem|Def|resp|approx|ca|No)\./g

export function analyse(src: string, kind: "md" | "tex", genre: Genre) {
  const { text, displays, inline } = toProse(src, kind)
  const lines = text.split("\n")
  // paragraphs with starting line
  const paras: { line: number; text: string; bullet: boolean }[] = []
  let buf: string[] = [], start = 0, bulletLines = 0, proseLines = 0
  const flush = () => {
    const s = buf.join(" ").replace(/\s+/g, " ").trim()
    if (s && !s.startsWith("#HEAD")) paras.push({ line: start + 1, text: s, bullet: s.startsWith("- ") })
    buf = []
  }
  lines.forEach((l, i) => {
    const s = l.trim()
    if (!s) return flush()
    if (s.startsWith("#HEAD")) { flush(); return }
    if (s.startsWith("- ")) { flush(); bulletLines++; proseLines++; start = i; buf.push(s); flush(); return }
    if (!buf.length) start = i
    proseLines++
    buf.push(s)
  })
  flush()

  const sentences: Sentence[] = []
  for (const p of paras) {
    const guarded = p.text.replace(ABBR, (m) => m.replace(/\./g, "․"))
    for (const raw of guarded.split(/(?<=[.!?])\s+(?=[A-Z0-9"(]|MATH|REF)/)) {
      const s = raw.replace(/․/g, ".").replace(/^- /, "").trim()
      const w = s.split(/\s+/).filter((x) => /[A-Za-z0-9]/.test(x)).length
      if (w >= 3) sentences.push({ line: p.line, text: s, words: w })
    }
  }
  const words = sentences.reduce((a, s) => a + s.words, 0)
  const proseWords = sentences.reduce((a, s) => a + s.text.split(/\s+/).filter((x) => /[A-Za-z]/.test(x) && x !== "MATH" && x !== "REF").length, 0)
  const per1k = (n: number) => (words ? (1000 * n) / words : 0)

  const flags: Flag[] = []
  const ex = (s: string) => (s.length > 140 ? s.slice(0, 137) + "..." : s).replace(/MATH/g, "$..$")
  let artifacts = 0, placeholders = 0
  let hedges = 0, stacks = 0, stock = 0, signposts = 0, transitions = 0, vague = 0, mathStart = 0, long = 0
  const hedgeRe = new RegExp(`\\b(${HEDGES.join("|")})\\b`, "gi")
  const stockCounts = new Map<string, number>()
  for (const s of sentences) {
    const plain = s.text.replace(HEDGE_EXEMPT, "")
    const h = (plain.match(hedgeRe) ?? []).length
    hedges += h
    if (h >= 2) { stacks++; flags.push({ line: s.line, reason: `${h} hedges in one sentence: state the condition instead`, excerpt: ex(s.text) }) }
    for (const [re, why] of STOCK) {
      re.lastIndex = 0
      const m = s.text.match(re)
      if (m) {
        stock += m.length
        for (const x of m) stockCounts.set(x.toLowerCase(), (stockCounts.get(x.toLowerCase()) ?? 0) + 1)
        flags.push({ line: s.line, reason: `${why} ("${m[0]}")`, excerpt: ex(s.text) })
      }
    }
    const art = s.text.match(ARTIFACT)
    if (art) { artifacts += art.length; if (LIMITS[genre].artifactRefs !== "allow") flags.push({ line: s.line, reason: `reference to research artifacts ("${art[0]}"): ${LIMITS[genre].artifactRefs === "forbid" ? "a paper must stand alone; describe the method or cite literature" : "keep such pointers in a marked further-reading box"}`, excerpt: ex(s.text) }) }
    const ph = s.text.match(PLACEHOLDER)
    if (ph) { placeholders += ph.length; flags.push({ line: s.line, reason: `placeholder ${ph[0]}`, excerpt: ex(s.text) }) }
    SIGNPOST.lastIndex = 0
    if (SIGNPOST.test(s.text)) { signposts++; flags.push({ line: s.line, reason: "signposting: show, don't announce", excerpt: ex(s.text) }) }
    if (TRANSITION_START.test(s.text)) { transitions++; flags.push({ line: s.line, reason: "stock transition at sentence start", excerpt: ex(s.text) }) }
    if (VAGUE_THIS.test(s.text)) { vague++; flags.push({ line: s.line, reason: "vague 'this': name the thing", excerpt: ex(s.text) }) }
    if (/^(MATH|REF)/.test(s.text)) { mathStart++; flags.push({ line: s.line, reason: "sentence starts with a symbol: start with a word", excerpt: ex(s.text) }) }
    if (s.words > 35) { long++; flags.push({ line: s.line, reason: `long sentence (${s.words} words)`, excerpt: ex(s.text) }) }
  }
  const emDashes = (text.match(/—|(?<!-)--(?!-)/g) ?? []).length
  const lens = sentences.map((s) => s.words).sort((a, b) => a - b)
  const mean = lens.length ? lens.reduce((a, b) => a + b, 0) / lens.length : 0
  const p90 = lens.length ? lens[Math.floor(0.9 * (lens.length - 1))] : 0
  const plens = paras.filter((p) => !p.bullet).map((p) => p.text.split(/\s+/).length)
  const pm = plens.reduce((a, b) => a + b, 0) / Math.max(1, plens.length)
  const cv = plens.length > 1 ? Math.sqrt(plens.reduce((a, b) => a + (b - pm) ** 2, 0) / plens.length) / pm : 0
  const openers = new Map<string, number>()
  for (const s of sentences) { const w = s.text.split(/\s+/)[0].toLowerCase(); openers.set(w, (openers.get(w) ?? 0) + 1) }
  const topOpener = [...openers.entries()].sort((a, b) => b[1] - a[1])[0]

  const L = LIMITS[genre]
  const m = {
    words, sentences: sentences.length, paragraphs: paras.length,
    hedgesPer1k: per1k(hedges), hedgeStacks: stacks, stockPhrases: stock, signposts, transitionsPer1k: per1k(transitions),
    vagueThis: vague, sentencesStartingWithSymbol: mathStart, inlineMathPer100: proseWords ? (100 * inline) / proseWords : 0,
    displayedEquations: displays, meanSentence: mean, p90Sentence: p90, longShare: sentences.length ? long / sentences.length : 0,
    emDashPer1k: per1k(emDashes), bulletShare: proseLines ? bulletLines / proseLines : 0, paragraphLengthCV: cv,
    artifactReferences: artifacts, placeholders,
    topOpener: topOpener ? `${topOpener[0]} (${Math.round((100 * topOpener[1]) / Math.max(1, sentences.length))}%)` : "-",
  }
  type Row = { metric: string; value: string; target: string; status: "ok" | "warn" | "fail" }
  const rows: Row[] = []
  const add = (metric: string, v: number, lim: number, fmt: (x: number) => string, failAt = 1.5) =>
    rows.push({ metric, value: fmt(v), target: `<= ${fmt(lim)}`, status: v <= lim ? "ok" : v <= lim * failAt ? "warn" : "fail" })
  const f1 = (x: number) => x.toFixed(1), pc = (x: number) => `${Math.round(100 * x)}%`, i0 = (x: number) => String(Math.round(x))
  add("hedges per 1000 words", m.hedgesPer1k, L.hedgesPer1k, f1)
  add("sentences with stacked hedges", stacks, 0, i0, Infinity)
  rows[rows.length - 1].status = stacks === 0 ? "ok" : stacks <= 2 ? "warn" : "fail"
  rows.push({ metric: "stock phrases and self-praise", value: i0(stock), target: `<= ${L.stockMax}`, status: stock <= L.stockMax ? (stock ? "warn" : "ok") : "fail" })
  rows.push({ metric: "signposting sentences", value: i0(signposts), target: "<= 1", status: signposts <= 1 ? "ok" : signposts <= 3 ? "warn" : "fail" })
  add("stock transitions per 1000 words", m.transitionsPer1k, L.transitionsPer1k, f1)
  rows.push({ metric: "vague 'this' openers", value: i0(vague), target: "<= 3", status: vague <= 3 ? "ok" : vague <= 6 ? "warn" : "fail" })
  rows.push({ metric: "sentences starting with a symbol", value: i0(mathStart), target: "0", status: mathStart === 0 ? "ok" : mathStart <= 2 ? "warn" : "fail" })
  add("inline math per 100 prose words", m.inlineMathPer100, L.mathPer100, f1)
  add("mean sentence length (words)", mean, L.meanSentence, f1, 1.25)
  add("share of sentences over 35 words", m.longShare, L.longShare, pc, 2)
  add("em dashes per 1000 words", m.emDashPer1k, L.emDashPer1k, f1, 2)
  add("bullet share of prose lines", m.bulletShare, L.bulletShare, pc, 2)
  rows.push({ metric: "paragraph length variation (CV)", value: cv.toFixed(2), target: ">= 0.30", status: plens.length < 8 || cv >= 0.3 ? "ok" : cv >= 0.2 ? "warn" : "fail" })
  const ar = L.artifactRefs
  rows.push({ metric: "references to research artifacts", value: i0(artifacts), target: ar === "forbid" ? "0" : ar === "tolerate" ? "few, in a marked box" : "any",
    status: ar === "allow" || artifacts === 0 ? "ok" : ar === "tolerate" ? (artifacts <= 10 ? "warn" : "fail") : "fail" })
  rows.push({ metric: "placeholders ([CITE], [CLAIM NEEDED])", value: i0(placeholders), target: "0 in a final draft", status: placeholders === 0 ? "ok" : "warn" })
  const verdict = rows.some((r) => r.status === "fail") ? "FAIL" : rows.some((r) => r.status === "warn") ? "WARN" : "PASS"
  flags.sort((a, b) => a.line - b.line)
  return { verdict, genre, metrics: m, rows, flags, stockCounts: Object.fromEntries(stockCounts) }
}

export function render(r: ReturnType<typeof analyse>, path: string, maxFlags = 30): string {
  const L = [
    `# stylecheck: ${path} (${r.genre}) - ${r.verdict}`,
    "",
    `${r.metrics.words} words, ${r.metrics.sentences} sentences, ${r.metrics.paragraphs} paragraphs, ${r.metrics.displayedEquations} displayed equations. Mean sentence ${r.metrics.meanSentence.toFixed(1)} words (90th percentile ${r.metrics.p90Sentence}). Most common opener: ${r.metrics.topOpener}.`,
    "",
    "| metric | value | target | status |",
    "| --- | --- | --- | --- |",
    ...r.rows.map((x) => `| ${x.metric} | ${x.value} | ${x.target} | ${x.status} |`),
    "",
    `## Flagged sentences (${r.flags.length}${r.flags.length > maxFlags ? `, first ${maxFlags} shown` : ""})`,
    "",
    ...r.flags.slice(0, maxFlags).map((f) => `- L${f.line}: ${f.reason}. "${f.excerpt}"`),
    "",
    "These are habits, not errors. Fix a flag when the rewrite is clearer; leave it with a reason when it is not (a hedge that states a real uncertainty, a long sentence that holds one idea). A clean report does not mean the text is good; the cold-reader test decides that.",
  ]
  return L.join("\n")
}
