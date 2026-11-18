# OpenCode research, review, and writing

Run `opencode-research` from the workspace and use `/research <question>` or
`/brief <idea>`, then `/goal` if you want a longer run. The launcher uses a
private server and separate managed config. OpenCode skips project config and
`AGENTS.md` discovery, but the workspace remains available as evidence. This is
instruction isolation, not a filesystem sandbox. `--proxy HOST:PORT` also works.

For open problems, use `/explore <problem>` for a bounded set of competing
approaches. It records decisions and connections in `research/ROUTES.md`,
uses the normal ledger to test them, and resumes with `/explore resume`.

In `opencode-research`, use `/review <document>`, `/write-brief`, or `/write`,
or switch between the `research`, `review`, and `write` agents. They all use
the isolated configuration. Ordinary `opencode` keeps the `/code-review`
code-diff workflow. `/calibrate` and `/style-note` write workspace examples
rather than modifying installed skills.

The review lead takes its own snapshot of the manuscript with `review_snapshot`.
For a multi-file paper, pass the workspace-relative manuscript directory to
`/review`. A snapshot is never overwritten; a changed source needs a new slug.

Profile models are resolved from the active OpenAI catalog at server startup
(restart the service or the private session after a catalog update). Only
canonical `gpt-<version>-<family>` releases match; aliases and fast/flex
variants do not. `/bench` shows the project dashboard; `/research-bench` gives
the detailed research report and labeling; `/review-bench` reports across
reviews (supply a path to run a planted experiment). Logs stay in
`research/bench/` and `review/bench/`, partitioned by exact model lineup.
Reports still read older review events from the mixed research log. A missing OpenAI tier is not a verified configuration;
check `opencode-research debug agents` before starting research.

The updated ledger issues worker and checker plans, tracks gates, and requires
a task-specific red-team decision before a V4 result can unblock dependents.
Old ledgers that recorded tier changes with `update` are not automatically
converted: preserve them and transfer evidence and unfinished tasks explicitly.
Use one research orchestrator per workspace; separate workspaces can run in
parallel. `/review-bench` generates planted errors in a copy, never the source.
Its scores are diagnostic, not ground truth about real-world recall.

The idle hook records reported usage and can send at most two corrective
messages per research session on a private server. Allowance weights are
estimates, not provider quota measurements. Routing presets live in
`kit/tiers.json`; they are not read from the project.
