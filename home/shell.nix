{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "eza --group-directories-first --color=auto";
      tree = "eza -T --icons";
      rm = "trash";
      cat = "bat";
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "z" "sudo" "colored-man-pages"];
      theme = "agnoster";
    };
  };

  programs.bat = {
    enable = true;
  };

  programs.bash.enable = true;  # Optional fallback

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = ["--cmd cd"];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
