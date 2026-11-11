# Neovim

Priority: **P1, active work target** (user direction, 2026-11-09). AI integration
is a main objective alongside a reliable coding and mathematical-writing
environment. This is the implementation plan, not permission to activate a
configuration or install every candidate below.

## Scope and rollout

- Keep the existing Home Manager `programs.neovim` + Lua structure. Nixvim is
  not currently used; a migration is unnecessary for AI integration.
- Keep plugins and runtime dependencies pinned through Nix. No lazy.nvim,
  Mason downloads, `npm install -g`, or `uv tool install` as the deployment path.
- Preserve VimTeX, texlab, SuperCollider integration, and normal offline editing.
- Use OpenCode as the initial coding agent and existing API providers for
  completions: no additional Copilot subscription, local model service, or
  replacement agent backend is required.
- Implement in separately verified batches: editor foundation → OpenCode
  integration → direct API completions. Graphify CLI/skill integration has
  proceeded in parallel; its research pilot is tracked in [`graphify.md`](graphify.md).
- Recommendations and example APIs below must be checked against the pinned
  packages when implementation starts; they are not tested configuration.
- Apply [`maintainability.md`](maintainability.md): one owner per editor action,
  upgrade checks, small Lua modules, and behavior-preserving cleanup before AI
  additions. Bleeding-edge features remain the higher priority.
- **Strict diagnostics are implemented in the candidate configuration**; keep
  formatting separate from linting and validate project-specific overrides.

## Progress snapshot (2026-11-09)

- [x] Replace Lua concatenation with store-backed `require("nixsama.…")` modules.
- [x] Remove `setup/gui.lua`, preserving nvim-tree/lualine/bufferline/font setup
      in the appearance module; remove the duplicate Treesitter setup.
- [x] Keep all Nix-managed grammars and remove the runtime parser install override.
- [x] Move editor-owned binaries to Neovim's wrapper PATH; add Alejandra there.
- [x] Explicit LuaSnip dependency and 33 lazy-loaded Python/C++/LaTeX snippets;
      preserve completion mappings and replace the old mixed snippet file.
- [x] Remove `init_old.lua` (confirmed absent in the working tree).
- [x] Add safe manual `:Black`, `:Alejandra`, `:Latexindent` commands and formatter
      regression tests. Existing `:ClangFormat` remains; user reported it works.
- [x] First/second diagnostic batches: strict Python/C++/LaTeX/Nix/Lua tooling,
      Nix-managed binaries, path completion, and reviewed fallback profiles.
- [x] Gutter `E/W/I/H` signs, debounced mouse-hover messages, and explicit
      `,af` / `:OpenCodeDiagnostic` preview with +/-2 source lines.
- [x] Nix-managed LTeX+ spelling/grammar for TeX and Markdown, with manual
      corrections and persistent project dictionaries/false-positive choices;
      see [`SPELLCHECK.md`](../../home/nvim/SPELLCHECK.md).

Candidate builds, isolated startup/tool lookup, snippet expansion/jump/mirror
checks, Python parsing, representative C++/LaTeX compilation, and formatter
repeat-run/undo/failure tests passed in the implementation sessions. Home Manager
evaluation and Nix formatting checks also passed. These are not evidence that
every latest change has been switched into the user's current editor process.
Real language-server/linter diagnostic integration and mocked gutter/OpenCode
tests passed. Interactive completion, terminal mouse reporting, and actual
project workflows still need manual acceptance. No automatic format-on-save
or automatic AI requests are enabled.

## Current state

| Item | Current | File |
|---|---|---|
| Entry point | `programs.neovim.initLua` requires `nixsama.*` modules; Home Manager deploys their directories under `nvim/lua/nixsama` | `home/nvim/nvim.nix` |
| Aliases | `vi`, `vim`, `vimdiff` | `home/nvim/nvim.nix` |
| Python/Ruby providers | disabled | `home/nvim/nvim.nix` |
| LSP/formatter/linter binaries | `alejandra`, `black`, `clang-tools`, `deadnix`, `ltex-ls-plus`, `lua-language-server`, `nixd`, `pyright`, `ruff`, `rust-analyzer`, `selene`, `statix`, `texlab`; latexindent/ChkTeX supplied by existing TeX Live | `home/nvim/nvim.nix` |
| Plugins | nvim-tree, nightfox, lualine, cmp, LuaSnip, treesitter, bufferline, lspconfig, nvim-lint, vimtex, scnvim; Mason/none-ls/vim-flake8 removed | `home/nvim/nvim.nix` |
| Treesitter | Keep `withAllGrammars` by user choice; one setup, no runtime `install_dir` override | `home/nvim/nvim.nix`, `lua/plugins/treesitter.lua` |
| Completion | `nvim-cmp` LSP/path/snippet sources + explicit LuaSnip; custom Python/C++/LaTeX collections lazy-loaded | `lua/plugins/{completion,snippets}.lua`; `home/nvim/SNIPPETS.md` |
| LSP setup | `vim.lsp.config` / `vim.lsp.enable` | `lua/plugins/lsp.lua` |
| Removed files | `init_old.lua`, `luasnip-snippets.lua`, `setup/gui.lua` | `home/nvim/lua/` |
| Formatter/linter | Manual `:Black`, `:Alejandra`, `:Latexindent`, and `:ClangFormat`; nvim-lint owns Statix/deadnix/Selene only, native LSP owns other diagnostics | `lua/core/formatting.lua`, `lua/plugins/{lint,lsp}.lua` |
| File finder | none (only nvim-tree) | — |
| Git integration | none | — |

## Concrete problems

1. **Mason ownership resolved.** Mason integrations are removed; Nix owns tools.
2. **Editor tool ownership resolved (2026-11-09).** Moved Black, clang-tools,
   Pyright, rust-analyzer, and texlab into `programs.neovim.extraPackages`.
   No other declared consumers/owners were found. A candidate build and isolated
   smoke test verified tool lookup from store paths inside Neovim and no remaining
   direct `home.packages` entries. Latest interactive activation is a separate check.
3. **Duplicate Treesitter setup resolved (2026-11-09).** Removed `setup/gui.lua`;
   appearance setup now lives in `setup/colorscheme.lua`. The plugin module
   owns Treesitter's only setup. Namespaced `require` calls replace Lua source
   concatenation. The candidate editor/config built and passed an isolated
   headless smoke test; activation and interactive testing remain separate.
4. **Runtime parser directory override removed.** Use Nix-provided parsers;
   do not recreate `stdpath("data")/parsers` as an installation target.
5. **Keep `withAllGrammars` (user decision).** Accept its build/download/storage
   cost; all parsers are not automatically loaded into memory on startup.
6. **LuaSnip dependency resolved.** It is explicitly listed alongside
   `cmp_luasnip`; no reliance on a transitive dependency.
7. **Custom snippets now loaded.** `plugins/snippets.lua` lazy-loads definitions
   from `snippets/{cpp,python,latex}.lua`; `tex` includes `latex`. The old
   mixed Go/C++ file was removed, with no duplicate Tab mappings or `_G` helpers.
8. **Old init copy removed.** `init_old.lua` is absent; Git preserves its history.
9. **Formatter/linter ownership resolved.** Keep manual formatter commands;
   native LSP plus nvim-lint provide diagnostics. none-ls/vim-flake8 are removed.
10. **`clipboard = "unnamedplus"` is unconditional.** On a headless/SSH
    session without `wl-copy`, yanks can hang or fail. Guard it on
    `WAYLAND_DISPLAY` and `executable("wl-copy")`.
11. **`conceallevel = 2` is global.** It hides markup in Markdown/LaTeX and
    can make prose confusing. Set it per filetype (Markdown/LaTeX only).
12. **`wildmenu` is legacy.** Neovim's modern popup menu uses
    `wildoptions=pum`; `set wildmenu` is at best a no-op. Verify on the
    installed version.
13. **No file finder or Git UI.** There is no Telescope/fzf-lua and no
    gitsigns. nvim-tree covers browsing, not fuzzy finding or hunk staging.
14. **`vim.lsp.config` requires a recent Neovim.** The config is written for
    the 0.11+ API. Confirm `nvim --version`; if the package is older, the LSP
    setup silently does nothing. On 0.11+, prefer an `LspAttach` autocmd for
    keymaps instead of relying on `on_attach` inside `vim.lsp.config`, whose
    support varies by version.
15. **Nix/Lua LSP resolved.** nixd and lua_ls are enabled and integration-tested.

## Target design

### Plugin and snippet audit (2026-11-09)

Inspected the pinned plugin entrypoints as well as our Lua configuration;
configuration absence alone does not imply a plugin does nothing.

This historical audit predates the diagnostic batches. Mason/none-ls/vim-flake8
have since been removed; nvim-lint is now configured intentionally.

| Component | Observed state at audit | Recommendation at audit |
|---|---|---|
| `mason-nvim` | `has_setup = false`; no configured package management | Remove; Nix already supplies editor tools |
| `mason-lspconfig-nvim` | No setup call | Remove alongside Mason; keep `nvim-lspconfig` |
| `mason-null-ls-nvim` | No setup call | Remove alongside Mason |
| `nvim-lint` | Empty `linters_by_ft`; no `try_lint` calls/autocommands in our config | Remove or deliberately configure as sole linter runner |
| `none-ls-nvim` | `_setup = false`; no configured sources | Remove unless selected as the formatting/linting bridge |
| `vim-flake8` | Registers Python F7 and `:Flake`; `flake8` executable absent | Remove/replace after confirming F7 is not a wanted workflow |
| `vim-clang-format` | Manual `:ClangFormat` available; automatic formatting off by default | Keep until deciding the C/C++ formatting workflow |
| Black executable | Available inside Neovim; no configured automatic invocation | Retain pending formatter choice; moving it does not enable formatting |

Mason installs/manages LSP servers, formatters, and linters at runtime. It is
useful outside Nix but adds a second package owner here. Removing its integration
plugins does not remove native Neovim LSP or Nix-managed server binaries.

The initial audit found unused Go/C++ snippets in `lua/luasnip-snippets.lua`.
That file is now replaced with 33 manual Python/C++/LaTeX snippets, explicitly
requested for the user's actual languages. See `home/nvim/SNIPPETS.md` for
triggers, mappings, and required LaTeX packages. Setup/loader code is separate
from definitions; completion keeps ownership of Tab/Shift-Tab. LSP-provided
snippet expansion remains supported through `luasnip.lsp_expand`.

The candidate wrapper built and passed an isolated headless test with the user
profile removed from PATH. All six commands (`black`, `clangd`, `clang-format`,
`pyright-langserver`, `rust-analyzer`, `texlab`) resolved to store paths. The
plugin states and absence of loaded custom snippets were checked at audit time;
the later snippet implementation supersedes that state. No Mason/formatter/linter
plugin was removed in that earlier foundation batch; see the current-state table
for later diagnostic-batch changes.

Keep the Nix-managed plugin model. Do **not** add `lazy.nvim` or Mason; both
move plugin/server installation out of the Nix store.

### Minimal, coherent plugin set

This table is a menu for later decisions, not a request to migrate every component.
Keep nvim-cmp and nvim-tree for the present foundation/AI round. Conform, a new
file finder, or a completion-engine migration is not already implemented.

| Concern | Recommended | Alternative |
|---|---|---|
| Completion | `blink.cmp` (fast, Rust fuzzy matcher) | keep `nvim-cmp` (mature, pure Lua) |
| Snippets | `luasnip` + `cmp_luasnip` / blink source | none |
| Fuzzy finder | `fzf-lua` (uses system `fzf`, fast) | `telescope.nvim` + `plenary.nvim` |
| File tree | keep `nvim-tree` | `oil.nvim` (edit filesystem as a buffer) or `mini.files` |
| Formatting | `conform.nvim` | `none-ls` |
| Linting | `nvim-lint` with explicit linters | `none-ls` |
| Git | `gitsigns.nvim` | `vim-fugitive` |
| Statusline | keep `lualine` | `mini.statusline` |
| Bufferline | keep `bufferline` or drop it and use `:bnext` | `barbar.nvim` |
| Colors | keep `nightfox` | `tokyonight`, `catppuccin` |
| LaTeX | keep `vimtex` | — |
| SuperCollider | keep `scnvim` | — |
| C/C++ | keep `clangd_extensions` | — |

Do not install both a formatter plugin and a linter plugin that also formats;
pick one owner per action.

### LSP and tools

```nix
programs.neovim.extraPackages = with pkgs; [
  # LSP servers
  pyright
  clang-tools
  rust-analyzer
  texlab
  nixd
  lua-language-server
  # Formatters/linters
  alejandra
  black
  ruff
  clang-tools
  stylua
  # Runtime helpers
  wl-clipboard
  fzf
  ripgrep
  fd
];
```

Remove the same packages from `home.packages` to avoid duplicates. Keep
`texliveFull`; `vimtex` needs `latexmk`, which comes from TeX Live. Keep
SuperCollider for `scnvim`.

LSP setup for 0.11+:

```lua
vim.lsp.config("*", {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

vim.lsp.config("pyright", { settings = { python = { analysis = {
  typeCheckingMode = "basic",
} } } })
vim.lsp.config("clangd", {})
vim.lsp.config("rust_analyzer", { settings = { ["rust-analyzer"] = {
  cargo = { allFeatures = true },
  checkOnSave = { command = "clippy" },
} } })
vim.lsp.config("texlab", {})
vim.lsp.config("nixd", {})
vim.lsp.config("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })

vim.lsp.enable({ "pyright", "clangd", "rust_analyzer", "texlab", "nixd", "lua_ls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  end,
})
```

This is more robust than passing `on_attach` through `vim.lsp.config`, and it
works for every server that attaches.

### Treesitter

Keep `nvim-treesitter.withAllGrammars` by user choice. The duplicate setup and
runtime installation directory override are removed. Check the pinned API
before changing highlighting/indentation options; parser selection is not a
cleanup prerequisite.

### Options to fix

- Guard `clipboard` on `WAYLAND_DISPLAY` and `wl-copy`.
- Set `conceallevel` only for Markdown/LaTeX (`vim.opt_local` in a `FileType`
  autocmd).
- Replace `wildmenu` with `wildoptions = "pum"` if supported.
- Add `undofile = true` with an `undodir` under `stdpath("state")`.
- Add `updatetime = 300`, `timeoutlen = 500`, `splitright`, `splitbelow`.
- Consider `relativenumber = true`; keep `number = true`.
- Keep `foldmethod = indent` and `foldlevel = 99` if you like open folds.
- Set `scrolloff = 8` (currently 7; cosmetic).
- Set `signcolumn = "yes"` (currently `'yes'`; same).
- `autowrite = true` can write files on `:next`; keep if intentional.
- `textwidth = 80` globally affects code; set per filetype instead.

### Completion

If keeping `nvim-cmp`, add sources:

```lua
sources = {
  { name = "nvim_lsp" },
  { name = "luasnip" },
  { name = "buffer" },
  { name = "path" },
}
```

Add `cmp-buffer`, `cmp-path`, and `cmp-cmdline` plugins. If moving to
`blink.cmp`, remove `nvim-cmp`, `cmp-*`, and `cmp_luasnip`; blink has its own
snippet and path sources. Test the Rust binary on this host before committing.

### Formatters and linters

#### Current manual commands

`lua/core/formatting.lua` defines whole-buffer `:Black` (Python), `:Alejandra`
(Nix), and `:Latexindent` (TeX/LaTeX). Each runs an argument-array subprocess
without a shell, uses stdin, captures stdout/stderr separately, and replaces
text only on success. They do not save or run automatically; `u` undoes the
formatting. Repeating a command on already-formatted text creates no new edit.
Wrong filetypes, nonmodifiable buffers, missing executables, formatter errors,
and timeouts are reported without replacing the buffer. A result is discarded
if the buffer changes during formatting. Named files use their directory as
the formatter working directory; Black also receives `--stdin-filename`.

`:Latexindent` uses the existing TeX Live installation, disables `indent.log`
with `-g /dev/null`, and does not enable line-break rewriting (`-m`). C/C++
retain the existing plugin's `:ClangFormat`. Raw `:%!formatter` filters are
discouraged: failures or merged informational stderr can pollute buffer text.

Regression test, with the candidate editor configuration loaded:

```sh
nvim --headless -c 'luafile tests/neovim-formatting.lua'
```

The test writes only to inherited `TMPDIR`; it checks real formatting, repeat
runs, single-step undo, no automatic saves/project logs, and failure handling.

#### Possible later unified integration

If adopting `conform.nvim`, replace the manual runners rather than keeping two
owners for the same formatting action. The following is a proposal, not active
configuration; automatic formatting requires a separate user decision:

```lua
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },     -- or "black"
    c = { "clang-format" },
    cpp = { "clang-format" },
    nix = { "alejandra" },
    rust = { "rustfmt" },
  },
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
})
```

Keep Black as the current Python formatter unless a replacement is deliberately
chosen. Ruff now owns Python linting and replaces the removed vim-flake8 plugin.

#### Strict diagnostics (implemented candidate)

The first two batches enable the following sources. Fallback profiles live in
`home/nvim/diagnostic-defaults/`; configuration is native LSP plus nvim-lint.

| Language | Diagnostic sources | Strictness/acceptance focus |
|---|---|---|
| Python | Pyright strict mode + Ruff | Type errors, unsafe/undefined usage, unused imports and reviewed broad lint rules; preserve Black formatting |
| C++ | clangd + clang-tidy + project compiler warnings | Correct compile database and language standard; correctness/bug-prone checks and reviewed warning set |
| LaTeX | texlab + ChkTeX | Compilation/reference diagnostics plus source lint; reviewed exceptions for project macros and intentional mathematical notation |
| TeX/Markdown prose | LTeX+ (local LanguageTool) | Spelling and grammar, markup-aware parsing, explicit correction/dictionary actions; US English default |
| Nix | nixd + Statix + deadnix | Evaluation/type feedback, static antipatterns and unused bindings; verify findings against module semantics |
| Lua | lua-language-server + Selene | Neovim API-aware checking, undefined globals and static lint; declare `vim`/LuaJIT environment explicitly |

Rules should be strict and actionable, not a blind “enable everything” switch:
some rule families conflict or impose project-specific conventions. Keep
project-local configuration for the actual Python version, C++ standard,
dependencies and TeX macros. Document narrow exceptions with reasons; avoid
blanket suppressions, duplicate diagnostics and warnings from vendored code.
Whether warnings fail CI is a separate explicit project decision, not a global
`-Werror` imposed on every dependency.

No automatic destructive fixes, import removal, or format-on-save is enabled by
this requirement. Complementary tools can coexist (e.g. Pyright types + Ruff
lint), with one owner per diagnostic category and one chosen editor runner for
each external tool. Prefer native LSP where appropriate; introduce nvim-lint or
another bridge only for tools that need it. Do not add both none-ls and another
runner for the same checks merely because both plugins are installed.

- [x] Add reviewed strict fallback configurations and Nix-managed binaries.
- [x] Configure editor diagnostics for Python/C++, LaTeX, Nix and Lua without
      duplicating LSP/linter reports.
- [x] Add representative known-bad and clean fixtures for each language; verify
      both editor diagnostics and reproducible CLI results.
- [ ] Check real project roots, compile databases, Python environments, and TeX
      include/macro handling before suppressing apparent false positives.
- [x] Replace/remove vim-flake8 or other existing lint components after the
      replacement is working; keep existing formatting commands intact.

**Policy and project overrides**

- Python: Pyright strict type checking; Ruff reviewed lint families, no automatic
  fixes/import organization/Ruff formatting. `pyrightconfig.json` or Pyright's
  `pyproject.toml` section controls environments/types. Ruff's project config
  wins over the managed fallback (`filesystemFirst`). This is a fallback, not
  a forced overlay on a project's chosen rules.
- C++: clangd uses the project's compilation database and standard. With no
  database, fallback warning flags apply. The managed `clangd/config.yaml`
  adds analyzer/bugprone/performance/portability and two modernization checks;
  `FastCheckFilter: Strict` intentionally excludes slow clang-tidy checks.
  `.clangd` `Diagnostics.ClangTidy.Remove` can narrow the managed Add list;
  `.clang-tidy` alone cannot remove checks re-added by the user config. No `-Werror`.
- LaTeX: texlab runs ChkTeX on edit/open/save, never automatic compilation.
  Settings arrive asynchronously, so a first-open lint may require an edit/save.
  ChkTeX uses texlab's project-root working directory; keep `.chktexrc` there
  and use narrow macro/notation exceptions. Compile/reference data still depend
  on the project's normal manual build/VimTeX workflow.
- Nix: nixd owns parser/name/type feedback; overlapping unused-definition
  diagnostics are suppressed in favor of deadnix. Statix uses nearest
  `statix.toml`; deadnix 1.3.2 reads saved files only (save to refresh).
- Lua: LuaLS uses LuaJIT and Neovim runtime types; Selene owns unused bindings
  and undefined globals. Nearest `selene.toml` takes precedence; fallback
  `lua51+vim` declares `vim`, `jit`, and `bit` without masking arbitrary globals.
- nvim-lint runs on read/save/InsertLeave; `:Lint` is the manual fallback.
  No checks mutate source. Dependencies/vendored code and real project roots
  still need project-specific acceptance rather than blanket global suppression.

**Gutter and OpenCode usage**

Warnings/errors appear beside the line numbers (`W`/`E`; `I`/`H` for lower
severities). Hover the gutter for a debounced message; this requires terminal
mouse-move reporting. `,e` remains the keyboard popup fallback.

On a diagnostic line, `,af` or `:OpenCodeDiagnostic` opens a preview containing
all diagnostics on that line plus exactly two surrounding lines on either side,
using unsaved buffer text. Check for secrets, then `s` sends; `q` cancels. The
existing `opencode --agent review --prompt …` wrapper runs in a terminal split
and asks for suggested fixes only. No automatic edits or requests occur.
This is the limited diagnostic bridge, not a full inline-edit/completion UI.
The payload/job invocation is tested with a mock; no paid inference was made.

Regression suite (candidate config/plugins and wrapper tools must be loaded):

```sh
nvim --headless -c 'luafile tests/neovim-diagnostics.lua'
nvim --headless -c 'luafile tests/neovim-formatting.lua'
```

Validation builds use a focused local-source flake import to include untracked
files without staging them; ordinary Git-filtered flake builds need these files
tracked first. No activation, lock update, or commit is part of this batch.

#### Alphabetical lists: separate from Alejandra formatting

The user requested alphabetical list ordering. Alejandra 4.1.0 has **no list-sort
option**: its [versioned configuration](https://github.com/kamadorueda/alejandra/blob/4.1.0/src/alejandra/src/config.rs)
supports indentation and bracket spacing only. A local stdin check confirmed
that `["zebra" "apple" "middle"]` retains its order. Do not invent an option or
silently add a sorting pass to `:Alejandra`.

Nix list order can affect PATH precedence, permissions, plugin initialization,
commands and fallback choices. Even package lists need review for ordering or
collision assumptions. Alphabetizing must therefore be an explicit operation on
a selected, reviewed list, preserving attached comments and item boundaries—not
a whole-file textual sort.

- [ ] Decide on a separate opt-in alphabetical package-list action or a reviewed
      manual cleanup. Never automatically sort every Nix list during formatting.

### Keymaps and UX

- `<leader>f` → `fzf-lua` files; `<leader>g` → live grep.
- `<leader>e` → nvim-tree toggle.
- `<leader>gs` → gitsigns stage hunk; `<leader>gp` → preview.
- `<leader>rn` → rename; `<leader>ca` → code action.
- `gd`, `gr`, `K` via `LspAttach`.
- `<leader>f` conflicts if you already use it; choose a prefix and document.

### Dead files

- `home/nvim/lua/init_old.lua` has been removed.
- Old `home/nvim/lua/luasnip-snippets.lua` removed; definitions now live in
  `lua/snippets/` and load via `lua/plugins/snippets.lua`.
- Keep `lua/core/{options,autocommands,mappings}.lua` and
  `lua/setup/colorscheme.lua`; these are loaded as namespaced modules.
- `lua/setup/gui.lua` was removed; its appearance setup was preserved in
  `lua/setup/colorscheme.lua`, and its duplicate Treesitter setup was dropped.
- Keep `lua/plugins/{lsp,completion,treesitter,vimtex}.lua` only if the
  corresponding plugins remain.

## AI integration (main target)

### Coding agent, inline requests, and review

Start by evaluating `nickjvandyke/opencode.nvim` against the installed OpenCode
version. It is the first candidate, not a compatibility guarantee. Inspect the
pinned plugin's protocol, dependencies, and documented Lua API before writing
configuration. If incompatible, evaluate a pinned compatible revision or
CodeCompanion/Avante ACP support; install only one agent UI. A terminal split
running the existing OpenCode wrapper remains the fallback.

Required interactions:

- Toggle agent chat/terminal and continue a project session.
- Send a visual selection, buffer, or diagnostics explicitly; show what context
  is being sent. Never upload an entire project by default.
- Request edits to a selection and multi-file agent changes. An inline edit
  request is distinct from automatic ghost-text completion; verify whether the
  chosen UI edits buffers or disk, including behavior with unsaved buffers.
- Review changes using Git hunks and a diff UI (Diffview is a candidate).
  Keep a documented undo/revert path. Post-edit Git review is not pre-edit
  permission approval; do not promise an approval dialog for auto-allowed edits.
- Keep the existing OpenCode wrapper and sandbox protections. Do not call a
  raw binary to bypass them or start unrestricted agents inside the editor.

Reserve `<leader>a` for AI actions. Proposed suffixes: `t` toggle, `a` ask,
`e` selection edit, `r` review selection, `f` diagnostics, `d` Git diff review,
`c` completion toggle. Audit current maps and terminal key encoding before
assigning bindings; these are target actions, not verified plugin commands.

### Automatic completions

Evaluate Minuet with an existing OpenAI-compatible provider. Verify the actual
endpoint, supported model, streaming/request schema, and billing entitlement;
sharing a provider with OpenCode does not imply its auth store or coding-plan
quota can be reused by a direct HTTP client.

- Start with manual triggering, then enable automatic completion for selected
  code filetypes after measuring latency and cost. LaTeX/Markdown can be opted
  in explicitly for research writing, not silently excluded forever.
- Set debounce, bounded context/output, and a request timeout using options
  actually supported by the pinned plugin. Avoid full manuscripts as context.
- Provide separate accept-full, accept-line, dismiss, cycle, trigger, and toggle
  bindings; avoid collisions with snippets, LSP completion, and terminal Alt keys.
- Keep LSP/snippet completion useful without network access. Do not install
  competing AI completion engines or send requests for every keystroke.
- Block secrets, `.env`, credential buffers, and explicitly private files from
  completion requests. Disabling suggestions visually must also stop requests.

### Credentials, network, and token budget

Minuet is a separate client, not a consumer of OpenCode's credential database.
Design its credential lookup with [`opencode.md`](opencode.md#7-editor-and-research-tool-boundaries).
Prefer a protected file or narrow credential helper over globally exported keys.
Do not export `DEEPSEEK_API_KEY` to all of Neovim simply to enable completions;
that changes the existing OpenCode-only secret boundary. Never embed secrets
in generated Lua, Nix derivations, Git, logs, or command-line arguments.

Keep the agent's loopback connection direct (`NO_PROXY`/`no_proxy` for localhost,
127.0.0.1, and ::1). First test an explicit working HTTP proxy. A direct-first
launcher with bounded probes and an optional interactive fallback is a later
convenience feature, not a prerequisite. No automatic sing-box deployment.
Account for OpenCode's persistent service: a new editor's environment does not
necessarily update an already-running server. Never silently replay a possibly
completed agent request after a connection failure.

Measure input/output tokens, cached tokens where reported, cost, latency, and
task success separately for agent work and completions. Use provider usage
records when available; a graph compression ratio is not an API cost measure.

### AI acceptance checklist

- [ ] Verify CLI/plugin compatibility and dependencies from pinned sources.
- [ ] Implement one agent UI through the existing wrapper; test project root,
      session reuse, unsaved buffers, and sandbox access to requested files.
- [ ] Implement context-aware chat, selection edits, diagnostics, and diff review.
- [ ] Add Minuet with existing-provider credentials outside the store and no
      global secret export; test model/endpoint with a minimal paid request.
- [ ] Test acceptance/dismissal and LSP/snippet/keymap coexistence.
- [ ] Verify excluded buffers make no requests; inspect logs for secret leakage.
- [ ] Test offline startup, failed authentication, timeout, proxy, and cancellation.
- [ ] Confirm approval/denial behavior in a disposable project, without broadening
      existing permissions to make the plugin appear to work.
- [ ] Compare representative Nix, Python, and LaTeX tasks with/without AI;
      record costs and missing usage data rather than guessing savings.
- [ ] Build the candidate editor and run headless startup checks before activation;
      interactive behavior and paid API calls require explicit manual testing.

## Foundation tasks

- [x] Confirm Neovim 0.12.6 supports `vim.lsp.config`/`enable` in candidate checks.
- [x] Deploy namespaced Lua modules and eliminate source concatenation.
- [ ] Remove Mason plugins and all runtime server installation.
- [x] Remove `install_dir`; keep one Treesitter setup; retain all grammars.
- [x] Add `luasnip` explicitly and load Python/C++/LaTeX snippets without
      conflicting keymaps.
- [x] Replace the old mixed `luasnip-snippets.lua` file.
- [x] Delete `init_old.lua`.
- [x] Move LSP/formatter binaries to `programs.neovim.extraPackages`; build and
      verify wrapper PATH (activation remains separate).
- [ ] Implement strict diagnostic sources/rules and verify replacements before
      retiring vim-flake8 or unused linting bridges; avoid duplicate runners.
- [ ] Guard `clipboard`; scope `conceallevel`.
- [x] Add Alejandra to the editor wrapper and safe manual formatting commands.
- [x] Build/run `tests/neovim-formatting.lua` against the isolated candidate.
- [ ] Add Nix/Lua LSP setup (`nixd`, `lua_ls`) and their editor dependencies.
- [ ] Enable the installed path-completion source; decide whether buffer completion
      is useful before adding more sources.
- [ ] Configure Ruff and the other strict diagnostic tools described above;
      existing manual formatting is not a linting pipeline.
- [ ] Decide separately whether StyLua or a unified formatting plugin is needed.
- [ ] Keep nvim-cmp/nvim-tree for this round; revisit alternatives only on request.
- [ ] Add `fzf-lua` (or Telescope) and `gitsigns`.
- [ ] Benchmark startup with `nvim --startuptime`.
- [ ] Run `:checkhealth` and fix only real errors.
- [ ] Wire deterministic editor tests into flake checks; current formatter tests
      are manual headless tests, not part of `nix flake check`.
- [ ] Manually verify snippets, real LSP attachment, VimTeX and scnvim after
      activating/restarting the editor; do not infer this from startup tests.

## Verification

```sh
nvim --version | head -3
nvim --headless "+checkhealth" +qa 2>&1 | tail -40
nvim --headless "+LspInfo" +qa 2>&1 | head -60
nvim --headless -c 'luafile tests/neovim-formatting.lua'
nvim --startuptime "$TMPDIR/nvim-start.log" +qa
sort -k2 -nr "$TMPDIR/nvim-start.log" | head -20
```

Use a candidate/activated configuration containing the new modules; set TMPDIR
to a writable scratch directory if it is not already defined. New flake source
files must be Git-visible before a normal flake build. Candidate checks previously
used an explicit local-source evaluation when new files were untracked; that is
not the same as a standard Git-filtered flake build. Stage deliberately; never
update the lock simply to expose new source files.

Manual: open Python/C++ files and confirm `gd`, `K`, rename, completion, snippets,
and `:Black`/`:ClangFormat`. Open Nix and test `:Alejandra` (Nix LSP remains
pending). Open `.tex` and test snippets, `:Latexindent`, VimTeX and texlab. Open
SuperCollider and confirm scnvim using `pw-jack nvim` where JACK is needed.
Format-on-save is not enabled and is not an acceptance requirement yet.

## Open questions

- Is the current nvim-cmp/LuaSnip setup worth keeping, or is a clean
  `blink.cmp` migration preferable?
- Do you use nvim-tree's file operations, or would `oil.nvim` be better?
- Telescope or fzf-lua?
- Is `scnvim` actively used enough to keep SuperCollider integration?
- Should formatting happen on save, or only on demand?
- Do you want a Nix LSP (`nixd`/`nil`) and `lua_ls` in this repo?
