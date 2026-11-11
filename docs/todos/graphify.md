# Graphify: OpenCode integration and research graphs

Priority: **P1**, in progress alongside Neovim. Status reconciled 2026-11-09
against the working tree. Integration exists; a reliable, representative
research-graph pilot and measured token/cost benefit remain acceptance gates.
This is not approval to index a project, upload documents, or make paid API calls.

## Implemented

- [x] Install the pinned `pkgs.graphify` through Home Manager, not pip/uv.
- [x] Add one curated `graphify` skill and allowlist it in OpenCode.
- [x] Add `/graphify`: discover project inputs, propose scope, build only on
      request, and retrieve source-grounded context. No automatic indexing.
- [x] Keep one workflow for code, research, and mixed projects; unsupported text
      sources use an adapter, not a parallel hand-authored substitute graph.
- [x] Add `graphify-prepare` and its offline tests. Both `graphify` and
      `graphify-prepare` were found on the installed PATH during this doc pass.
- [x] Ignore `graphify-out/` in Git and OpenCode's watcher. Configure
      `GRAPHIFY_QUERY_LOG_DISABLE=1`; recipes also set it explicitly.
- [x] Preserve shell approval and read-only specialist roles. No upstream
      installer, MCP server, hooks, watcher, or save-result loop is enabled.

Sources:

- `home/opencode/opencode.nix`: package ownership, helper wrapper, command,
  permission allowlist, environment and skill deployment.
- `home/opencode/graphify.md`: operational workflow and privacy/provenance rules.
- `home/opencode/graphify-prepare.py`: deterministic corpus preparation.
- `tests/test_graphify_prepare.py`: five offline unit tests.
- `flake.nix`: separate `packages.x86_64-linux.graphify-deepseek` candidate.

## Research/TeX handling

Pinned Graphify 0.9.91 does not natively classify Nix or TeX as supported code.
The integration therefore discovers relevant originals first, including notes,
manuscripts, macros, local includes, bibliography and mathematical implementations.
The skill directs the agent to resolve dependencies; the helper itself does not
traverse directories or resolve TeX includes.

`graphify-prepare` accepts an explicit JSON allowlist with `copy` / `text` modes:

- `copy` preserves extensions for supported code/documents.
- `text` appends `.md` and copies original UTF-8 bytes verbatim. A `.tex`,
  `.sage`, `.wl`, or `.nix` source can thus reach semantic extraction without
  compiling code, stripping formulas, or inventing an AST extractor.
- `preparation.json` records source/prepared paths, zero line offset, SHA-256,
  byte sizes, UTC preparation time, and Git revision/dirty state.
- Default limits: 2 MiB per file and 10 MiB total. New output directories must
  be below the project's `graphify-out/`. Existing outputs are not overwritten.
- Symlinks, traversal, binary/non-UTF-8 data, collisions and obvious sensitive
  paths are rejected. This is defense in depth, not guaranteed secret detection.

Preparation is **not extraction**. Preserved bytes/line numbers do not establish
that Graphify extracts mathematical statements accurately or cites them exactly.
PDF/OCR and structured notebooks need separate reviewed conversion plans.

## Extraction, retrieval and publication contract

The curated skill owns the exact command recipes; avoid duplicating a second
incompatible workflow here. Its current requirements are:

1. Approve source scope and any semantic backend/model, data transfer, and cost.
2. Prepare a fresh bounded corpus, preserving originals and their mapping.
3. Let Graphify extract: code-only for genuinely code-only selections; semantic
   extraction for research/documents. `--code-only` is not complete TeX coverage.
4. Use `PYTHONHASHSEED=0` for pinned 0.9.91's Nix re-exec issue. Bounded workers
   and `--no-cluster` avoid unnecessary processing. `--token-budget` is per chunk,
   not a global spending cap.
5. Use `--no-gitignore` only on the prepared allowlisted corpus inside ignored
   output, never to bypass ignores on the original workspace.
6. Validate coverage, source citations and representative claims before publishing
   `graphify-out/graph.json` plus matching `provenance.json`. Preserve the last
   valid graph on failure; preparation's manifest is not publication provenance.
7. Query small subgraphs, map citations back to original sources, and check
   freshness using inventory/hashes, not just a dirty flag.
8. Refresh only on request into a fresh build; check new/deleted sources and
   dependency changes. Do not assume a code-only reset removes old semantic nodes.

Important limits: EXTRACTED means source-explicit, not mathematically proved;
INFERRED means inferred. A graph path is not a verified proof-dependency chain.
Keep exact assumptions, equations and claim status in authoritative research
sources. Fall back to ordinary source search if a graph is missing or unverified.

## Default DeepSeek semantic extraction routine

User direction: use this routine by default for semantic graph construction;
plain installed `graphify` remains the local code-only/retrieval CLI. From any
project directory, reference `/home/spamdoodler/nixos#graphify-deepseek` explicitly;
the `.#graphify-deepseek` shorthand works only from this configuration repository.
The curated skill owns the extraction recipe, including explicit `--backend deepseek`.
This default is not approval for automatic uploads, indexing or paid calls.

`nix run .#graphify-deepseek -- --help` inspects the headless backend CLI.
The flake package adds the OpenAI SDK/tiktoken optional dependencies,
patches DeepSeek requests to use `max_tokens`, and logs finish reason/token counts.
Its wrapper sets `PYTHONHASHSEED=0` locally.

This is **not** the plain `pkgs.graphify` installed by Home Manager. Do not assume
the installed CLI includes those extras/patches, or that an OpenCode subscription
or auth store grants independent Graphify API access. Backend credentials and
inference spending require separate approval. No fresh API extraction or cost
validation was performed during this documentation update.

- [ ] Record a reproducible smoke check of the patched package and request
      schema, including a failed/truncated response; do not count exit 0 alone.
- [x] Document the patched flake package / DeepSeek as the default semantic
      routine; keep pilot-specific model, scope and cost approval explicit.
- [ ] Record patch removal conditions and recheck them on Graphify upgrades.

## Verification and remaining acceptance

**Checked in this doc pass:** five preparation-helper tests passed. They cover
verbatim mixed TeX/code inputs, mappings/hashes, forbidden paths, symlink/binary
rejection, collisions/limits and no-overwrite/output confinement. They do not
exercise Graphify semantic extraction, source accuracy, or a paid provider.

With the flake's Nix-provided Python available:

```sh
python3 tests/test_graphify_prepare.py
```

Neither this Python suite nor the Neovim formatter suite is currently wired
into flake `checks`; those outputs still cover desktop scripts and RTW89 options.

- [ ] Choose and approve one representative research/mixed project and backend.
- [ ] Validate native supported-code extraction and the text adapter end-to-end;
      assert coverage of TeX, macros, notes and relevant computations explicitly.
- [ ] Check exact statements, hypotheses, equations and source links against
      originals; report omissions instead of labelling partial output complete.
- [ ] Exercise query/explain/path, ambiguity/no-match responses and source mapping.
- [ ] Test stale/new/deleted source handling and failure-safe publication.
- [ ] Record approved usage/cost and inspect truncation/finish reasons before
      increasing scope. No savings percentage is established yet.
- [ ] Compare representative tasks against plain OpenCode using source accuracy,
      resolved issues, latency, tokens and total indexing/query cost.
- [ ] Add deterministic helper tests to flake checks; keep paid extraction out
      of normal checks and CI.
- [ ] Document retention/backup of authoritative notes versus rebuildable indexes.

Related: [`opencode.md`](opencode.md), [`tools.md`](tools.md), and
[`nvim.md`](nvim.md). QMD, Beads, Zotero, and editor AI integration remain separate
future work; Graphify's CLI/skill integration does not implement them.
