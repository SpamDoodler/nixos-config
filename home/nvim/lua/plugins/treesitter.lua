require("nvim-treesitter.install").install_dir = vim.fn.stdpath("data") .. "/parsers"


-- Treesitter configuration
require("nvim-treesitter").setup {
  -- Enable syntax highlighting
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true,
  },

  -- Enable incremental selection
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",    -- start selection
      node_incremental = "grn",  -- expand to next node
      scope_incremental = "grc", -- expand to scope
      node_decremental = "grm",  -- shrink node
    },
  },

  -- Enable indentation based on treesitter
  indent = {
    enable = true,
  },

  -- Enable autotagging (if you add nvim-ts-autotag plugin via pkgs.vimPlugins)
  -- autotag = {
  --   enable = true,
  -- },
}
