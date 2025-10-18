{
  config,
  pkgs,
  ...
}: {
  home = {
    pointerCursor = {
      gtk.enable = true;
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      hyprcursor.enable = true;
    };
  };
}
