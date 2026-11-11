local defaults = vim.fn.stdpath("config") .. "/diagnostic-defaults"

vim.lsp.config("*", {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

-- Do not replace each server's own on_attach (which defines useful commands).
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("NixSamaLspKeys", { clear = true }),
  callback = function(event)
    local opts = { silent = true, buffer = event.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    local function line_actions()
      -- A gutter/hover message is line-based; the default zero-width cursor
      -- range misses LTeX actions unless the cursor is inside the flagged word.
      local line = vim.api.nvim_win_get_cursor(0)[1]
      vim.lsp.buf.code_action({ range = {
        start = { line, 0 },
        ["end"] = { line, #vim.api.nvim_get_current_line() },
      } })
    end
    vim.keymap.set("n", "<F4>", line_actions, { buffer = event.buf, desc = "Diagnostic actions for this line" })
    vim.keymap.set("x", "<F4>", vim.lsp.buf.code_action, { buffer = event.buf, desc = "Actions for selection" })
    vim.keymap.set("n", "<leader>ca", line_actions, opts) -- Compatibility alias.
    vim.keymap.set("x", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false -- Pyright owns hover/types.
      client.server_capabilities.documentFormattingProvider = false -- Keep Black.
      client.server_capabilities.documentRangeFormattingProvider = false
    end
  end,
})

vim.lsp.config("pyright", {
  settings = {
    pyright = { disableOrganizeImports = true },
    python = { analysis = {
      typeCheckingMode = "strict",
      diagnosticMode = "openFilesOnly",
      -- Ruff owns these lint categories; Pyright owns type checking.
      diagnosticSeverityOverrides = { reportUnusedImport = "none", reportUnusedVariable = "none" },
    } },
  },
})

vim.lsp.config("ruff", {
  init_options = { settings = {
    configuration = defaults .. "/ruff.toml",
    configurationPreference = "filesystemFirst",
    fixAll = false,
    organizeImports = false,
    showSyntaxErrors = false, -- Pyright already reports syntax errors.
  } },
})

vim.lsp.config("clangd", {
  cmd = { "clangd", "--clang-tidy", "--enable-config", "--background-index" },
  -- Compilation databases remain authoritative; no language standard is forced.
  init_options = { fallbackFlags = { "-Wall", "-Wextra", "-Wpedantic", "-Wconversion", "-Wshadow" } },
})

vim.lsp.config("rust_analyzer", {
  settings = { ["rust-analyzer"] = {
    cargo = { allFeatures = true },
    check = { command = "clippy" },
  } },
})

vim.lsp.config("texlab", {
  settings = { texlab = {
    chktex = { onOpenAndSave = true, onEdit = true },
    build = { onSave = false, forwardSearchAfter = false },
  } },
})

vim.lsp.config("ltex_plus", require("nixsama.plugins.ltex"))

vim.lsp.config("nixd", {
  settings = { nixd = { diagnostic = {
    -- deadnix owns unused bindings; keep nixd's parser/name/type diagnostics.
    suppress = { "sema-unused-def-let", "sema-unused-def-lambda", "sema-unused-def-lambda-arg" },
  } } },
})
vim.lsp.config("lua_ls", {
  settings = { Lua = {
    runtime = { version = "LuaJIT" },
    workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
    diagnostics = {
      -- Selene owns unused bindings and undefined globals; keep type diagnostics.
      disable = { "unused-local", "unused-function", "undefined-global" },
      severity = {
        ["assign-type-mismatch"] = "Error",
        ["param-type-mismatch"] = "Error",
        ["return-type-mismatch"] = "Error",
        ["missing-return"] = "Error",
      },
    },
    telemetry = { enable = false },
  } },
})

vim.lsp.enable({ "pyright", "ruff", "clangd", "rust_analyzer", "texlab", "ltex_plus", "nixd", "lua_ls" })
