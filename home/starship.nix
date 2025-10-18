{
  config,
  pkgs,
  ...
}: {
  programs.starship = {
    enable = true;
    settings = {
      format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$character";
      add_newline = false;
      character.success_symbol = "[>](bold green)";
      character.error_symbol = "[>](bold red)";
      directory.truncate_to_repo = false;
      directory.truncation_symbol = "…";
      git_branch.always_show_remote = true;
      git_branch.format = "[$symbol$branch(:$remote_name/$remote_branch)]($style) ";
      time.format = "[$time]($style) ";
      time.disabled = false;

      rust.disabled = true;
      nix_shell.format = "[$symbol]($style) ";
      nix_shell.symbol = " ";
    };
  };
}
