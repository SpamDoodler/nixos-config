import { tool } from "../lib/tool.ts"
import { realpathSync } from "node:fs"
import { isAbsolute, relative } from "node:path"
import { appendJsonl, now, readText, workspacePath } from "../lib/core.ts"
import { analyse, render, type Genre } from "../lib/style.ts"

export default tool({
  description:
    "Deterministic prose check for Markdown or LaTeX drafts: hedges, stacked hedges, stock 'AI' phrases and self-praise, signposting, vague 'this', " +
    "sentences that start with a symbol, inline-math density, sentence length, em dashes, bullets, paragraph uniformity. Limits depend on the genre. " +
    "Returns a table and line-numbered flags. With `slug`, appends the metrics to writing/<slug>/lint-history.jsonl so revisions can be compared.",
  args: {
    path: tool.schema.string().describe("File to check (.md or .tex)"),
    genre: tool.schema.enum(["physics-paper", "math-paper", "lecture-notes", "report"]).describe("Sets the limits"),
    slug: tool.schema.string().optional().describe("Writing project slug, to log the result"),
    max_flags: tool.schema.number().int().min(0).max(200).optional().describe("Flags to show (default 30)"),
  },
  async execute(a, ctx) {
    const path = isAbsolute(a.path) ? relative(realpathSync(ctx.directory), a.path) : a.path
    const parts = path.split("/")
    if (parts.length < 3 || parts[0] !== "writing" || !/\.(md|tex)$/.test(path) ||
        (a.slug !== undefined && a.slug !== parts[1]))
      return "ERROR: check a Markdown/TeX file under writing/<slug>/, with a matching slug if supplied."
    const p = workspacePath(ctx.directory, ...parts)
    const kind = p.endsWith(".tex") ? "tex" : "md"
    const r = analyse(readText(p), kind, a.genre as Genre)
    if (a.slug)
      appendJsonl(workspacePath(ctx.directory, "writing", a.slug, "lint-history.jsonl"), {
        t: now(), file: path, genre: a.genre, verdict: r.verdict, ...r.metrics, flags: r.flags.length,
      })
    return render(r, path, a.max_flags ?? 30)
  },
})
