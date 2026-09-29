{
  config,
  pkgs,
  ...
}: {
  home = {
    pointerCursor = {
      enable = true;
      gtk.enable = true;
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      hyprcursor.enable = true;
    };
  };
}
