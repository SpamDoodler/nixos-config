local set = vim.opt

-- Leader key
vim.g.mapleader = ","

-- General options
set.mouse = 'a'
set.incsearch = true
set.hlsearch = true
set.ignorecase = true
set.smartcase = true
set.tabstop = 4
set.shiftwidth = 4
set.expandtab = true
set.smartindent = true
set.foldmethod = 'indent'
set.foldlevel = 99
set.number = true
set.signcolumn = 'yes'
set.autowrite = true
set.switchbuf = 'usetab'
set.scrolloff = 7
set.autoread = true
set.cmdheight = 1
set.hidden = true
set.syntax = 'on'
set.termguicolors = true
set.wildmenu = true
set.wildmode = {'longest','list','full'}

-- Extra editor options
vim.o.conceallevel = 2
vim.opt.textwidth = 80
vim.o.clipboard = 'unnamedplus'

-- Line number highlight
vim.cmd [[
highlight clear SignColumn
highlight LineNr term=bold cterm=None ctermfg=DarkGrey ctermbg=None gui=None guifg=DarkGrey guibg=NONE
]]

-- Filetype plugin support
vim.cmd [[
filetype plugin on
filetype indent on
]]
