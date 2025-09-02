vim.o.conceallevel = 2
vim.opt.textwidth = 80
vim.o.clipboard = 'unnamedplus'

vim.opt.guifont = { "Cascadia Code", "h15" }

-- shortcuts
vim.keymap.set('n', '<F3>', ':NvimTreeToggle<CR>', { noremap = true })

-- nvim-tree-lua
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- lualine-nvim
require('lualine').setup({
  options = {theme = 'nord', section_separators='', component_separators=''}
})

-- nvim-treesitter
require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all"
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

-- bufferline-nvim
require("bufferline").setup{}
