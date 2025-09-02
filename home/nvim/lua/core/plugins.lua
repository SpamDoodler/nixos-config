-- Disable netrw for nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Ensure packer is installed
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git','clone','--depth','1','https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
  end
end
ensure_packer()

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- Plugins
  use 'nvim-tree/nvim-tree.lua'
  use 'nvim-lualine/lualine.nvim'
  use 'akinsho/bufferline.nvim'
  use 'EdenEast/nightfox.nvim'
  use {'nvim-treesitter/nvim-treesitter', run=':TSUpdate'}
  use 'neovim/nvim-lspconfig'      -- LSP configurations
  use 'williamboman/mason.nvim'    -- Package manager for LSPs, DAPs, linters
  use 'williamboman/mason-lspconfig.nvim' -- Bridges mason and lspconfig

  use 'hrsh7th/nvim-cmp'           -- Completion engine
  use 'hrsh7th/cmp-nvim-lsp'       -- LSP completion source
  use 'L3MON4D3/LuaSnip'           -- Snippet engine
  use 'saadparwaiz1/cmp_luasnip'   -- Snippet completion source
end)
