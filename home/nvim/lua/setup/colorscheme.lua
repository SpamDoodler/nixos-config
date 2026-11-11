-- Appearance setup lives here, not in a separate GUI-only entrypoint.
-- These plugins also configure the terminal UI.
vim.opt.guifont = { "Cascadia Code", "h15" }

require("nvim-tree").setup()
require("lualine").setup({
  options = { theme = "nord", section_separators = "", component_separators = "" },
})
require("bufferline").setup({})

vim.cmd [[colorscheme nightfox]]

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "*.sage",
    command = "set filetype=python"
})
