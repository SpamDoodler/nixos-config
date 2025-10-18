{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    # This is the default user
    userName = "spamdoodler";
    userEmail = "raphael.senghaas@gmx.de";

    # Conditional inculdes
    extraConfig = {
      core.editor = "nvim";
      core.sshCommand = "ssh -i ~/.ssh/id_rsa_spamdoodler";
      init.defaultBranch = "main";

      includeIf."gitdir:~/Uni/".path = "${config.xdg.configHome}/git/config-uni";
    };
  };

  home.file."${config.xdg.configHome}/git/config-uni".text = ''
    [user]
      name = "rsenghaas"
      email = "raphael.senghaas@gmail.com"

    [core]
      sshCommand = "ssh -i ~/.ssh/id_rsa_rsenghaas"
  '';
}
