local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

-- Manual snippets only. Environments such as theorem/lemma/proof must be
-- provided by the document preamble (typically amsthm); align uses amsmath.
return {
  s({ trig = "beg", name = "Environment" }, fmta([[
    \begin{<>}
        <>
    \end{<>}
  ]], { i(1, "environment"), i(0), rep(1) })),
  s({ trig = "sec", name = "Section with label" }, fmta([[
    \section{<>}
    \label{sec:<>}
    <>
  ]], { i(1, "Title"), i(2, "label"), i(0) })),
  s({ trig = "ssec", name = "Subsection" }, fmta([[
    \subsection{<>}
    <>
  ]], { i(1, "Title"), i(0) })),
  s({ trig = "eq", name = "Numbered equation" }, fmta([[
    \begin{equation}
        \label{eq:<>}
        <>
    \end{equation}
  ]], { i(1, "label"), i(0, "a = b") })),
  s({ trig = "ali", name = "Aligned equations (amsmath)" }, fmta([[
    \begin{align}
        <> &= <> \\
        <> &= <>
    \end{align}
  ]], { i(1, "a"), i(2, "b"), i(3, "c"), i(0, "d") })),
  s({ trig = "thm", name = "Theorem (requires defined environment)" }, fmta([[
    \begin{theorem}
        \label{thm:<>}
        <>
    \end{theorem}
  ]], { i(1, "label"), i(0) })),
  s({ trig = "lem", name = "Lemma (requires defined environment)" }, fmta([[
    \begin{lemma}
        \label{lem:<>}
        <>
    \end{lemma}
  ]], { i(1, "label"), i(0) })),
  s({ trig = "proof", name = "Proof (amsthm)" }, fmta([[
    \begin{proof}
        <>
    \end{proof}
  ]], { i(0) })),
  s({ trig = "frac", name = "Fraction (math mode)" }, fmta([[
    \frac{<>}{<>}
  ]], { i(1, "numerator"), i(2, "denominator") })),
  s({ trig = "sum", name = "Sum (math mode)" }, fmta([[
    \sum_{<>=<>}^{<>} <>
  ]], { i(1, "k"), i(2, "1"), i(3, "n"), i(0, "a_k") })),
  s({ trig = "int", name = "Integral (math mode)" }, fmta([[
    \int_{<>}^{<>} <>\,\mathrm{d}<>
  ]], { i(1, "a"), i(2, "b"), i(3, "f(x)"), i(0, "x") })),
  s({ trig = "ref", name = "Cross-reference" }, fmta([[
    \ref{<>}
  ]], { i(1, "label") })),
  s({ trig = "cite", name = "Citation" }, fmta([[
    \cite{<>}
  ]], { i(1, "key") })),
}
