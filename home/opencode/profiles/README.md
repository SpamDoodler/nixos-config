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

Use `/review <document> rigor=L` for Lean-certified review. For research,
select L and its scope in `/brief` or in the goal. Every substantive claim
in scope needs a matching, replayed certificate and an axiom audit; P and M
remain available and the defaults are unchanged.

The review lead takes its own snapshot of the manuscript with `review_snapshot`.
For a multi-file paper, pass the workspace-relative manuscript directory to
`/review`. A snapshot is never overwritten; a changed source needs a new slug.

Profile models are resolved from the active OpenAI catalog at server startup
(restart the service or the private session after a catalog update). Only
canonical `gpt-<version>-<family>` releases match; aliases and fast/flex
variants do not. The deployment ladder uses Luna `medium`, Terra `low` and
`medium`, Sol `low` and `high`, and Astra `xhigh` and `max`. Astra `max` is
available for documented, approved P1 escalations after Astra `xhigh` has
failed, but excluded from automatic routing. Terra Medium is benchmark-only.
The first dispatch runs a separate blind batch of Luna Medium, Terra Low,
Terra Medium and Sol Low; the main worker is selected separately. If a newer
model lacks its requested variant, the plugin
warns and uses that model's default. `/bench` shows the project dashboard; `/research-bench` gives
the detailed research report and labeling; `/review-bench` reports across
reviews (supply a path to run a planted experiment). Logs stay in
`research/bench/` and `review/bench/`, partitioned by exact model lineup and
reasoning variants so earlier runs are not mixed with the new defaults.
Writing runs are not benchmarked. Style checks and style notes remain available.

Reference only: [Artificial Analysis OpenAI table](https://artificialanalysis.ai/models/creators/openai),
Intelligence Index v5.0.1. GPT-6 Luna Medium scores 18; GPT-6.1 Terra Low/Medium
29/38; GPT-6.2 Sol Low/High 41/55; GPT-6.2 Astra xhigh/Max 62/62. These are
release-specific external scores, not probabilities, router weights, or
scores for future model releases.
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
estimates, not provider quota measurements. Production dispatch uses the
configured priors in `kit/tiers.json` and escalates through the production
ladder. New or reset benchmark history does not change these defaults.
Use `bench route` to review evidence-based suggestions manually.
