-- LSP keymaps on attach
local on_attach = function(client, bufnr)
    local opts = { noremap=true, silent=true, buffer=bufnr }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)       -- Go to definition
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)             -- Hover documentation
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)   -- Rename symbol
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Code actions
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)       -- Find references
end

local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Python LSP
vim.lsp.config('pyright', {
    on_attach = on_attach,
    capabilities = cmp_capabilities,
})

-- C/C++ LSP
vim.lsp.config('clangd', {
    on_attach = on_attach,
    capabilities = cmp_capabilities,
})

-- Rust LSP
vim.lsp.config('rust_analyzer', {
    on_attach = on_attach,
    capabilities = cmp_capabilities,
    settings = {
        ['rust-analyzer'] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
        },
    },
})

-- LaTeX LSP
vim.lsp.config('texlab', {
    on_attach = on_attach,
    capabilities = cmp_capabilities,
})

