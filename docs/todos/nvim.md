# Neovim

Priority: **P2, deferred**. Do not implement these recommendations yet. This
file records the current design, the concrete bugs, and a menu of clean
replacements for a later pass.

## Current state

| Item | Current | File |
|---|---|---|
| Entry point | `programs.neovim` with `initLua` assembled from files | `home/nvim/nvim.nix:44-56` |
| Aliases | `vi`, `vim`, `vimdiff` | `home/nvim/nvim.nix:13-15` |
| Python/Ruby providers | disabled | `home/nvim/nvim.nix:17-18` |
| LSP binaries | `black`, `clang-tools`, `pyright`, `rust-analyzer`, `texlab` | `home/nvim/nvim.nix:2-8` |
| Plugins | nvim-tree, nightfox, lualine, cmp, treesitter, bufferline, mason, lspconfig, vimtex, scnvim | `home/nvim/nvim.nix:21-43` |
| Treesitter | `withAllGrammars`, runtime `install_dir` | `home/nvim/nvim.nix:26`, `lua/plugins/treesitter.lua:1` |
| Completion | `nvim-cmp` + `cmp_luasnip`; LuaSnip required | `lua/plugins/completion.lua` |
| LSP setup | `vim.lsp.config` / `vim.lsp.enable` | `lua/plugins/lsp.lua` |
| Dead files | `init_old.lua`, `luasnip-snippets.lua` | `home/nvim/lua/` |
| Formatter/linter | `black`, `vim-flake8`, `nvim-lint`, `none-ls` installed, no config | `nvim.nix:35-40` |
| File finder | none (only nvim-tree) | — |
| Git integration | none | — |

## Concrete problems

1. **Mason downloads at runtime.** `mason-nvim`, `mason-lspconfig`, and
   `mason-null-ls` are in the plugin list (`nvim.nix:28-30`), but no
   `require("mason").setup()` is loaded. They are dead weight; if enabled
   later, Mason would download LSP servers outside Nix, breaking
   reproducibility and offline builds.
2. **LSP binaries are installed globally.** `pyright`, `clangd`,
   `rust-analyzer`, and `texlab` are in `home.packages`, so every shell gets
   them. Prefer `programs.neovim.extraPackages` to put them only in
   Neovim's wrapper `PATH`.
3. **Treesitter is configured twice.** `gui.lua:16-18` calls
   `require("nvim-treesitter").setup`, then `plugins/treesitter.lua:1-42`
   sets `install_dir` and calls setup again. The two options conflict
   (`additional_vim_regex_highlighting` is `false` then `true`). Only one
   setup should exist.
4. **`install_dir` fights the Nix wrapper.** Nix-managed grammars live in the
   plugin's own path. Pointing `nvim-treesitter.install` at
   `stdpath("data")/parsers` can make it look for or try to install parsers
   outside the store. Remove it; use the Nix-provided grammars.
5. **`withAllGrammars` is huge.** It builds and installs every parser, which
   is slow to build, large in the store, and unnecessary. Select the
   languages you actually edit (Nix, Lua, Python, C/C++, Rust, LaTeX,
   Markdown, Bash, JSON, YAML, TOML).
6. **LuaSnip is not explicit.** `completion.lua` does
   `require("luasnip")`, but the plugin list contains `cmp_luasnip`, not
   `luasnip`. `cmp_luasnip` may propagate the dependency, but do not rely on
   a transitive dependency; add `luasnip` explicitly or remove the snippet
   integration.
7. **Snippets are never loaded.** `lua/luasnip-snippets.lua` exists but is not
   read by `initLua`; it is dead code. Either load it or delete it.
8. **`init_old.lua` is dead.** It is not read by `nvim.nix`; delete it to
   avoid confusing future edits.
9. **Formatter/linter plugins are unconfigured.** `vim-flake8` needs
   `flake8`, which is not installed; `nvim-lint` and `none-ls` have no setup;
   `black` is installed but nothing invokes it. This is three half-solutions
   for one problem.
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
15. **No Nix/Lua LSP.** For a NixOS repo, `nixd` (or `nil`) and `lua_ls` are
    more useful than another Python linter.

## Target design (for the later pass)

Keep the Nix-managed plugin model. Do **not** add `lazy.nvim` or Mason; both
move plugin/server installation out of the Nix store.

### Minimal, coherent plugin set

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

```nix
nvim-treesitter.withGrammars [
  "bash" "c" "cpp" "json" "lua" "markdown" "nix"
  "python" "rust" "toml" "vim" "vimdoc" "yaml" "latex"
]
```

Verify the exact attribute name (`withGrammars` vs a function) against the
pinned nixpkgs. Remove `install_dir` and the duplicate setup. Keep one setup
call with `highlight.enable = true`, `indent.enable = true`, and
`additional_vim_regex_highlighting = false`.

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

Use `conform.nvim`:

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

Use `ruff` for Python lint/format instead of `vim-flake8` + `black` +
`nvim-lint`. If you prefer `black`, keep `black` and use `ruff` only for
linting. Remove `vim-flake8`; it is unmaintained and `flake8` is not
installed.

### Keymaps and UX

- `<leader>f` → `fzf-lua` files; `<leader>g` → live grep.
- `<leader>e` → nvim-tree toggle.
- `<leader>gs` → gitsigns stage hunk; `<leader>gp` → preview.
- `<leader>rn` → rename; `<leader>ca` → code action.
- `gd`, `gr`, `K` via `LspAttach`.
- `<leader>f` conflicts if you already use it; choose a prefix and document.

### Dead files

- Delete `home/nvim/lua/init_old.lua`.
- Either load `home/nvim/lua/luasnip-snippets.lua` from `initLua` or delete
  it.
- Keep `lua/core/{options,autocommands,mappings}.lua` and
  `lua/setup/{gui,colorscheme}.lua`; they are all loaded.
- Keep `lua/plugins/{lsp,completion,treesitter,vimtex}.lua` only if the
  corresponding plugins remain.

## Tasks (deferred)

- [ ] Confirm `nvim --version` supports `vim.lsp.config`/`enable`.
- [ ] Remove Mason plugins and all runtime server installation.
- [ ] Remove `install_dir`; keep one treesitter setup; select grammars.
- [ ] Add `luasnip` explicitly or remove snippet support.
- [ ] Delete `init_old.lua`; load or delete `luasnip-snippets.lua`.
- [ ] Move LSP/formatter binaries to `programs.neovim.extraPackages`.
- [ ] Replace `vim-flake8`/`none-ls`/`nvim-lint` with one formatter and one
      linter.
- [ ] Guard `clipboard`; scope `conceallevel`.
- [ ] Add `nixd`, `lua_ls`, `ruff`, `stylua`, `alejandra`.
- [ ] Choose `nvim-cmp` vs `blink.cmp`.
- [ ] Choose `nvim-tree` vs `oil.nvim` vs `mini.files`.
- [ ] Add `fzf-lua` (or Telescope) and `gitsigns`.
- [ ] Benchmark startup with `nvim --startuptime`.
- [ ] Run `:checkhealth` and fix only real errors.

## Verification (when the work starts)

```sh
nvim --version | head -3
nvim --headless "+checkhealth" +qa 2>&1 | tail -40
nvim --headless "+LspInfo" +qa 2>&1 | head -60
nvim --startuptime /tmp/nvim-start.log +qa
sort -k2 -nr /tmp/nvim-start.log | head -20
```

Manual: open a Python file and confirm `gd`, `K`, rename, format-on-save, and
completion; open a Nix file and confirm `nixd`; open a `.tex` file and confirm
`vimtex` + `texlab`; open a SuperCollider file and confirm `scnvim`.

## Open questions

- Is the current nvim-cmp/LuaSnip setup worth keeping, or is a clean
  `blink.cmp` migration preferable?
- Do you use nvim-tree's file operations, or would `oil.nvim` be better?
- Telescope or fzf-lua?
- Is `scnvim` actively used enough to keep SuperCollider integration?
- Should formatting happen on save, or only on demand?
- Do you want a Nix LSP (`nixd`/`nil`) and `lua_ls` in this repo?