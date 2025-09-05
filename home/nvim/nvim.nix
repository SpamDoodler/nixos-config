{config, pkgs, ... }:

{
  home.packages = with pkgs; [
    black
    clang-tools
    pyright
    rust-analyzer
    texlab
  ];
  programs.neovim = {
		enable = true;

    # Aliases 
		viAlias = true;
		vimAlias = true;
		vimdiffAlias = true;

    # Plugins
		plugins =
		  (with pkgs.vimPlugins; [
		    nvim-tree-lua
		    nightfox-nvim
		    lualine-nvim
        cmp_luasnip
		    nvim-treesitter.withAllGrammars
		    bufferline-nvim
        mason-nvim
        mason-null-ls-nvim
        mason-lspconfig-nvim
        nvim-lspconfig
        nvim-cmp
        cmp-path
        cmp-nvim-lsp
        vim-flake8
        vim-clang-format
        clangd_extensions-nvim
        nvim-lint
        none-ls-nvim
        vimtex
		  ]);
		# extraConfig = (builtins.readFile ./init.vim) ;
    extraLuaConfig = ''
      ${builtins.readFile ./lua/core/options.lua}
      ${builtins.readFile ./lua/core/autocommands.lua}
      ${builtins.readFile ./lua/core/mappings.lua}
      ${builtins.readFile ./lua/setup/gui.lua}
      ${builtins.readFile ./lua/setup/colorscheme.lua}
      ${builtins.readFile ./lua/plugins/lsp.lua}
      ${builtins.readFile ./lua/plugins/completion.lua}
      ${builtins.readFile ./lua/plugins/bufferline.lua}
      ${builtins.readFile ./lua/plugins/treesitter.lua}
      ${builtins.readFile ./lua/plugins/nvim-tree.lua}
      ${builtins.readFile ./lua/plugins/vimtex.lua}
    '';
	};
}
