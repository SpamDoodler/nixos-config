{pkgs, ...}: {
  # Keep the native Lua modules store-backed and namespaced on Neovim's
  # runtime path. Historical files outside these directories stay unloaded.
  xdg.configFile = {
    "nvim/lua/nixsama/core".source = ./lua/core;
    "nvim/lua/nixsama/plugins".source = ./lua/plugins;
    "nvim/lua/nixsama/setup".source = ./lua/setup;
    "nvim/lua/nixsama/snippets".source = ./lua/snippets;
    "nvim/diagnostic-defaults".source = ./diagnostic-defaults;
    "clangd/config.yaml".source = ./diagnostic-defaults/clangd.yaml;
  };

  programs.neovim = {
    enable = true;

    # Editor tools belong to Neovim's wrapper PATH, not every user shell.
    extraPackages = with pkgs; [
      alejandra
      black
      clang-tools
      deadnix
      ltex-ls-plus
      lua-language-server
      nixd
      pyright
      ruff
      rust-analyzer
      selene
      statix
      texlab
    ];

    # Aliases
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withPython3 = false;
    withRuby = false;

    # Plugins
    plugins = with pkgs.vimPlugins; [
      bufferline-nvim
      clangd_extensions-nvim
      cmp-nvim-lsp
      cmp-path
      cmp_luasnip
      lualine-nvim
      luasnip
      nightfox-nvim
      nvim-cmp
      nvim-lspconfig
      nvim-lint
      nvim-tree-lua
      nvim-treesitter.withAllGrammars
      scnvim
      vim-clang-format
      vim-matchup
      vimtex
    ];
    initLua = ''
      -- Initialization has dependencies; do not alphabetize these calls.
      require("nixsama.core.options")
      require("nixsama.core.autocommands")
      require("nixsama.core.mappings")
      require("nixsama.core.formatting")
      require("nixsama.core.diagnostics")
      require("nixsama.core.opencode")
      require("nixsama.setup.colorscheme")
      require("nixsama.plugins.snippets")
      require("nixsama.plugins.completion")
      require("nixsama.plugins.lsp")
      require("nixsama.plugins.lint")
      require("nixsama.plugins.treesitter")
      require("nixsama.plugins.vimtex")
    '';
  };
}
