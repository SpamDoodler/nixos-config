""""" GENERAL SETTINGS """""

" Set ergonomic <leader> key
let mapleader = ","

" Change between buffers 
map <C-J> :bprev<CR>
map <C-K> :bnext<CR>

" Change between windows
map <C-H> <C-W>h
map <C-L> <C-W>l
tnoremap <ESC> <C-\><C-n>

" This will enable the usage of your mouse inside Vim
set mouse=a

set incsearch
set hlsearch
set ignorecase
set smartcase


vmap j gj
vmap k gk
nmap j gj
nmap k gk

set tabstop=4
set shiftwidth=4
set smarttab
set expandtab
set smartindent

" Folding
set foldmethod=indent
set foldlevel=99

" Line numbers
set number
highlight clear SignColumn
highlight LineNr term=bold cterm=None ctermfg=DarkGrey ctermbg=None gui=None guifg=DarkGrey guibg=NONE

" Autowrite on disk on buffer switching, exit, etc
set autowrite

set switchbuf=usetab

filetype plugin on
filetype indent on
set scrolloff=7

set autoread

syntax on

" Language indentation settings
autocmd FileType asm setlocal tabstop=4 softtabstop=0 noexpandtab shiftwidth=4
autocmd FileType go setlocal tabstop=4 softtabstop=0 noexpandtab shiftwidth=4

autocmd FileType norg setlocal tabstop=2 shiftwidth=2 nowrap
autocmd FileType nix setlocal tabstop=2 shiftwidth=2
autocmd FileType lua setlocal tabstop=2 shiftwidth=2
autocmd FileType haskell setlocal tabstop=2 shiftwidth=2

autocmd FileType python setlocal tabstop=4 shiftwidth=4
autocmd FileType cpp setlocal tabstop=4 shiftwidth=4
autocmd FileType c setlocal tabstop=4 shiftwidth=4

" Other language-specific settings
function SwapKeysTex()
  :inoremap <buffer> ; \
  :inoremap <buffer> \ ;

  :inoremap <buffer> ' $
  :inoremap <buffer> $ '

  :inoremap <buffer> / \f{}{}<Left><Left><Left>
endfunction
" autocmd FileType tex call SwapKeysTex()
let g:tex_conceal = ""

" Do not close the buffer when changing them
set hid

" Wildmenu
set wildmenu
set wildmode=longest:list,full

set cmdheight=1

" Needed for italics, underlines and proper colors for some plugins
set termguicolors

" Colorscheme
colorscheme nightfox
