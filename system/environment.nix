{
  config,
  pkgs,
  lib,
  ...
}: {
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
}
