-- Font (for GUI clients)
vim.opt.guifont = { "Cascadia Code", "h15" }

-- nvim-tree default setup
require("nvim-tree").setup()

-- lualine
require('lualine').setup({
  options = { theme = 'nord', section_separators='', component_separators='' }
})

-- bufferline
require("bufferline").setup{}

-- treesitter
require('nvim-treesitter.configs').setup {
  highlight = { enable = true, additional_vim_regex_highlighting = false },
}
