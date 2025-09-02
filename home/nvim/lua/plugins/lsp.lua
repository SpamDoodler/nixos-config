local lspconfig = require("lspconfig")

local on_attach = function(client, bufnr)
    local opts = { noremap=true, silent=true, buffer=bufnr }
    -- Keymaps for LSP
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)    -- Go to definition
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)          -- Hover documentation
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- Rename symbol
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Code actions
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)    -- Find references
end


local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Python LSP
lspconfig.pyright.setup{
    on_attach = on_attach,
    capabilities = cmp_capabilities,
}

-- C/C++ LSP
lspconfig.clangd.setup{
    on_attach = on_attach,
    capabilities = cmp_capabilities,
}

-- Rust LSP
lspconfig.rust_analyzer.setup{
    on_attach = on_attach,
    capabilities = cmp_capabilities,
    settings = {
        ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
        }
    }
}

