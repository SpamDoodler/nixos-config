# Tools and workflow

Priority: **P1/P2**. AI/research tooling is a planned follow-on to Neovim;
other CLI suggestions remain optional. Add tools in measured stages rather
than deploying every candidate at once.

## AI and research tool rollout

User direction (2026-11-09): use AI tooling on this system, with Neovim and AI
integration as the next main target. This section records intended pilots,
not verified upstream feature claims or approval to run repository-wide scans.
Use [`nvim.md`](nvim.md) for editor integration and [`opencode.md`](opencode.md)
for agent/credential boundaries.

### Stage 1 — editor workflow

OpenCode agent integration + Minuet direct API completions + Git/diff review.
No new subscription and no mandatory Nixvim migration. Finish this stage before
adding multiple retrieval systems; ordinary source search remains the baseline.

### Stage 2 — persistent research context

| Candidate | Intended role | Pilot / adoption gate |
|---|---|---|
| Graphify | Navigable relationships across code and research documents | One project; inspect exact extraction, provenance, freshness, language support, and token cost |
| QMD | Passage retrieval over research notes and diaries | Compare with `rg`; verify packaging, local model downloads, RAM/storage, and NixOS runtime |
| Beads | Persistent tasks and blockers | One project's unresolved questions; test worktree/Git behavior and current database/service requirements |
| Zotero CLI or MCP integration | Bibliography, annotations, and paper access | Identify the actual maintained integration; start read-only against a backed-up library |

The previous package inspection found `pkgs.graphify` and `pkgs.beads`, but not
`pkgs.qmd`; recheck the current lock before implementation. A package's existence
does not guarantee optional PDF/MCP/model backends are included. Verify exact
CLI flags, skill installation paths, and OpenCode compatibility from the pinned
source. Do not run installer commands that overwrite project instructions or
the managed OpenCode configuration. Package missing tools reproducibly or use
a pinned project environment, not global npm/uv installs.

Adopt tools incrementally, one measured pilot at a time. Graphify's semantic
document extraction may incur model calls; neither its output nor inferred
relationships establish mathematical validity. Indexes are disposable derived
data, not authoritative research memory. Preserve source paths and revisions,
refresh after changes, and test deletion/staleness behavior.

Keep authoritative LaTeX, diaries, and explicit claim records in project Git:
statement, hypotheses, status (proved/conditional/computationally checked/
conjectural/refuted/superseded), source reference, and dependencies. Distinguish
retrieved facts from model inference. Do not claim native LaTeX extraction or
exact equation fidelity without testing it; convert selectively if needed.

### Stage 3 — specialist capabilities, only when needed

- arXiv retrieval and PaperQA2 for literature search and cited evidence;
  verify exact source versions, equation transcription, and provider support.
- Serena for symbol navigation in supported implementation languages; evaluate
  separately for Nix/LaTeX instead of assuming every language is supported.
- Context7 for current programming documentation and Repomix for explicit
  portable snapshots; review what content leaves the project.
- Lean integration for selected formalizable claims, with actual compiler
  checks; a successful numerical calculation is not a general proof.
- Marker if PDF extraction is a demonstrated bottleneck; assess local resource
  cost and equation quality before indexing a large library.
- Use existing OpenCode agents/skills before adding another orchestration layer.
  LiteLLM, GPT Researcher, Graphiti, and automatic network routing remain later
  candidates, not default services.

### Installation, privacy, and acceptance

- [ ] Inventory current package versions and plugin/CLI compatibility; pin every
      installed component and record its owner (Home Manager vs project devShell).
- [ ] Pick one research project and explicit included paths. Exclude credentials,
      `.opencode-tmp`, private journals, generated output, and third-party corpora
      unless deliberately included. Review whether extracted snippets leave disk.
- [ ] Check OS sandbox access to project indexes, model caches, tool state, and
      read-only Zotero access; do not expose the entire home directory.
- [ ] Prefer CLI + on-demand skills when sufficient. Enable MCP servers only
      for workflows that need them; measure schema/context overhead too.
- [ ] Benchmark project-state reconstruction, exact literature lookup, and a
      cross-file proof audit against the plain OpenCode workflow. Count initial
      indexing, reindexing, local model costs, and subsequent query costs.
- [ ] Record source accuracy, missed hypotheses, task success, latency, tokens,
      and cost; only expand after a useful pilot and a documented rollback.
- [ ] Document state locations, rebuild/reindex procedure, and what needs backup.

## Install map

| Tool | Package | Where |
|---|---|---|
| `atuin` | `pkgs.atuin` or `programs.atuin` | Home Manager |
| `tealdeer` | `pkgs.tealdeer` | Home Manager |
| `dust` | `pkgs.dust` | Home Manager |
| `sd` | `pkgs.sd` | Home Manager |
| `xh` | `pkgs.xh` | Home Manager |
| `hyperfine` | `pkgs.hyperfine` | Home Manager |
| `jless` | `pkgs.jless` | Home Manager |
| `just` | `pkgs.just` | Home Manager |
| `typos` | `pkgs.typos` | Home Manager / pre-commit |
| `uv` | `pkgs.uv` | Home Manager |
| `plocate` | `pkgs.plocate` + `services.locate` | NixOS |
| `nh` | `pkgs.nh` | Home Manager |
| `nix-output-monitor` | `pkgs.nix-output-monitor` (`nom`) | Home Manager |
| `nvd` | `pkgs.nvd` | Home Manager |
| `nix-tree` | `pkgs.nix-tree` | Home Manager |

Add them in one place, not both system and Home. For a first pass, add the
small CLI tools to `home.packages` and `plocate` to `services.locate` (see
[`maintenance.md`](maintenance.md)).

## atuin — searchable shell history

Atuin records command history in SQLite with context (directory, exit code,
duration), and replaces Ctrl-R with a fuzzy search UI. Sync is optional and
end-to-end encrypted; local-only is the privacy-preserving default.

```nix
programs.atuin = {
  enable = true;
  enableZshIntegration = true;
  settings = {
    auto_sync = false;
    search_mode = "fuzzy";
    filter_mode = "global";
    history_filter = [
      "^export .*KEY=.*"
      "^export .*TOKEN=.*"
      "^opencode auth"
    ];
  };
};
```

```sh
atuin import auto          # one-time import of existing zsh history
atuin search --limit 20
atuin stats
# Ctrl-R opens the interactive search
```

Use it when “what was that command I ran in this repo last week?” is a real
question. The history filter is a safety net, not a guarantee; never rely on
it to keep secrets out of a synced history. If you enable sync, back up the
encryption key.

## tealdeer — practical examples for CLI tools

`tealdeer` is a fast `tldr` client: short, example-driven man pages instead of
full manuals.

```sh
tldr --update
tldr tar
tldr rsync
tldr --list | head
```

Use it before `man` when you need the common flags. Examples are
community-maintained; verify destructive commands against `--help` before
running them.

## dust — intuitive disk usage

`dust` is a `du` alternative with a tree and bar chart.

```sh
dust -d 2                 # depth 2
dust -s                   # summary only
dust -r                   # reverse (largest last)
dust -X target            # exclude a directory (verify flag)
```

Use it to find what filled the disk. Use `ncdu` when you want an interactive
browser and `du -sh *` when you want a scriptable answer.

## sd — find and replace

`sd` is a simpler `sed` for literal/regex replacement.

```sh
sd 'old' 'new' file.txt
sd -p 'old' 'new' file.txt       # preview only
sd -F 'a.b' 'x' file.txt         # fixed string, not regex
```

Use it for one-off edits. It replaces all matches by default; commit or back
up first. For structured edits, use your editor or a language script; `sd`
does not understand syntax.

## xh — friendly HTTP requests

`xh` is a fast `curl` alternative with sensible defaults and JSON support.

```sh
xh GET https://httpbin.org/json
xh POST https://httpbin.org/post name=John
xh GET https://api.example.com/items \
  Authorization:"Bearer $TOKEN"
xh --download https://example.com/file.iso
```

Use it for API poking and JSON; use `curl` in scripts where ubiquity matters.
Never paste real tokens into a command that will be saved in shell history;
prefix with a space (if `HIST_IGNORE_SPACE` is set) or use an environment
file.

## hyperfine — benchmarks

`hyperfine` runs commands repeatedly, warms caches, and reports statistical
timings.

```sh
hyperfine 'fd pattern' 'find . -name pattern'
hyperfine --warmup 3 'zsh -i -c exit'
hyperfine --prepare 'sync' 'command'
hyperfine --export-markdown bench.md 'cmd1' 'cmd2'
```

Use it to decide whether a change actually helped. Do not benchmark commands
that mutate state unless you understand the side effects; use `--prepare` to
reset between runs.

## jless — JSON pager

`jless` is an interactive JSON viewer with folding and search.

```sh
jless file.json
curl -s https://httpbin.org/json | jless
```

Keys: arrows/`j`/`k` navigate, `/` searches, `Enter` folds, `q` quits. Use
`jq` for processing and `jless` for exploring; `jq . file.json | less` is the
fallback.

## just — project command runner

`just` is a modern `make` for project commands. It does not replace Nix; it
records the commands you would otherwise paste.

```make
# justfile
test:
    cargo test

fmt:
    alejandra .

check: fmt test

serve port="8000":
    python3 -m http.server {{port}}
```

```sh
just --list
just test
just serve 9000
just --choose          # fuzzy pick a recipe
```

Use it for repeated project tasks. Keep recipes short and non-destructive;
put secrets in environment variables, not in the `justfile`.

## typos — source spell checker

`typos` finds misspellings in source, comments, and docs while ignoring
identifiers and code.

```sh
typos
typos --diff
typos -w                 # write corrections
```

Configuration (`.typos.toml`):

```toml
[files]
extend-exclude = ["target", ".direnv", "result"]

[default]
extend-ignore-re = ["[A-Z]{2,}"]
```

Use it in pre-commit; review `-w` changes, because it can “fix” intentional
names.

## uv — Python environments and tools

`uv` is a fast Python package/project manager. It can replace `pip`, `pipx`,
`virtualenv`, and `pyenv` for many workflows.

```sh
uv venv
uv pip install requests
uv run python script.py
uvx ruff check .
uv init myproject
uv add requests
uv sync
```

NixOS caveat: `uv python install` downloads standalone Python builds that may
not run because they expect a non-Nix dynamic loader. Prefer a Nix-provided
Python:

```sh
nix shell nixpkgs#python3
uv venv --python "$(command -v python3)"
# or: export UV_PYTHON_PREFERENCE=only-system
```

Do not commit `.venv` or `uv.lock` unless the project is meant to be
reproducible without Nix. For Nix projects, a devShell with `python3` and
`uv` is usually cleaner than mixing both package managers.

## plocate — fast global file search

`plocate` maintains a compressed database of file names and searches it much
faster than `find /`.

```sh
sudo updatedb
plocate flake.nix
plocate -i nixos
plocate -l 20 '*.pdf'
```

Use `plocate` for “where is that file anywhere on the system?”, `fd` for
project-local searches, and `rg` for content. Enable the timer with
`services.locate` (see [`maintenance.md`](maintenance.md)); prune
`/nix/store`, caches, and Steam to keep the database small.

## nh — Nix helper

```sh
nh os switch
nh os boot
nh os test
nh home switch
nh clean all --keep 5
nh search ripgrep
```

`nh` wraps `nixos-rebuild`, shows a package diff, and cleans generations. It
does not make a bad configuration safe; read the build output and keep the
plain commands as a fallback.

## Nix observability

### nix-output-monitor (`nom`)

```sh
sudo nixos-rebuild switch --flake .#NixSama |& nom
nom build .#NixSama
```

`nom` turns Nix’s line-oriented build log into a readable tree with progress
and failures. Use it when a rebuild is slow or fails in a dependency.

### nvd

```sh
nvd diff /run/current-system ./result
nvd diff /run/current-system /nix/var/nix/profiles/system-42-link
```

`nvd` shows package/version changes between two system closures. Use it after
`nixos-rebuild build` and before switching.

### nix-tree

```sh
nix-tree /run/current-system
nix why-depends /run/current-system /nix/store/...-package
```

`nix-tree` interactively explores why a closure is large. Use it before
removing a package “for space” when you do not know what pulls it in.

## Already-installed small utilities

| Tool | What it does | Example |
|---|---|---|
| `tdf` | TUI PDF viewer | `tdf paper.pdf` |
| `lie` | Lie group computations | `lie --help` (math workflow) |
| `ueberzugpp` | Draws images in terminals | used by terminal file managers/previewers |
| `ani-cli` | Browse/play anime via `mpv` | `ani-cli` |
| `pamixer` | PulseAudio CLI mixer | `pamixer -i 5`, `pamixer -t` |
| `gphoto2` | Camera capture/download | `gphoto2 --auto-detect` |
| `openconnect` | VPN client | `sudo openconnect vpn.example.com` |
| `nmap` | Network scanner | `nmap -sV 192.168.1.0/24` (own network only) |
| `smartmontools` | Disk SMART data | `sudo smartctl -a /dev/nvme0n1` |
| `libinput` | Input debugging | `libinput debug-events` |
| `bottom` | System monitor TUI | `btm` |
| `ncdu` | Interactive disk usage | `ncdu /home` |
| `fastfetch` | System info summary | `fastfetch` |
| `tmux` | Terminal multiplexer | `tmux new -s work`, `tmux a -t work` |
| `yazi` | Terminal file manager | `y` |
| `trash-cli` | Safe delete/restore | `trash file`, `trash-list`, `trash-restore` |
| `delta` | Git diff pager | `git diff` (once configured) |
| `eza` | Modern `ls` | `eza -l --git` |
| `bat` | Syntax-highlighted `cat` | `bat file` |
| `fzf` | Fuzzy finder | `Ctrl-T`, `fd | fzf` |
| `zoxide` | Frecent directory jump | `z project` |
| `direnv` | Per-project environments | `echo 'use flake' > .envrc; direnv allow` |

Remove the ones you do not use; an unused CLI tool is still a package to
update and a potential source of confusing aliases.

## Writing a small helper

C++ is fine if no existing tool fits the workflow. Keep the source in this
repo under `scripts/` (or a small `tools/` directory), build it in a devShell,
and do not add a compiler to the system closure just for one helper. A minimal
`shell.nix`:

```nix
{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [gcc cmake pkg-config];
}
```

```sh
nix develop -c cmake -S . -B build
nix develop -c cmake --build build
```

Use `writeShellApplication` for glue scripts; choose C++ when the work is
CPU-heavy, needs binary parsing, or depends on a library that is awkward in
shell. Promote the helper to `home.packages` only after it is used regularly.

## Suggested workflow

1. `z project` → `direnv` loads the devshell → `just test`.
2. `rg pattern` for content, `fd name` for files, `plocate` for the system.
3. `bat`/`eza` for reading, `sd` for a quick edit, `jless`/`xh` for APIs.
4. `hyperfine` before/after a performance change.
5. `typos` + `alejandra` + `nix flake check` before a commit.
6. `nh os switch`; `nvd diff` if the closure changed; `nom` if it failed.
7. `atuin search` when you cannot remember the command.

## Tasks

- [ ] Add only the tools you will actually use.
- [ ] Configure `atuin` local-only and import history.
- [ ] Add `tealdeer`, `dust`, `sd`, `xh`, `hyperfine`, `jless`, `just`,
      `typos`, `uv`, `plocate`, `nh`.
- [ ] Enable `services.locate` with `plocate`.
- [ ] Add `nom`, `nvd`, `nix-tree` for Nix debugging.
- [ ] Add a `justfile` to one real project.
- [ ] Add `typos` to pre-commit.
- [ ] Try `uv` with a Nix-provided Python, not a downloaded one.
- [ ] Remove tools that remain unused after a month.

## Open questions

- Do you want Atuin sync, or local-only?
- Should `uv` manage Python projects outside Nix, or should every project use
  a devShell?
- Is `just` preferable to `make` for your C++/SuperCollider projects?
- Do you want `tealdeer` examples in English only, or another language?
- Which of the already-installed utilities can be removed?
