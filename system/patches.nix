{
  config,
  pkgs,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      # hy3 0.56 does not compile against hyprutils 0.14.3, which ships with
      # Hyprland 0.57. Use the plugin release built for Hyprland 0.57.
      hyprlandPlugins =
        prev.hyprlandPlugins
        // {
          hy3 = prev.hyprlandPlugins.hy3.overrideAttrs (old: {
            version = "0.57.0";
            src = prev.fetchFromGitHub {
              owner = "outfoxxed";
              repo = "hy3";
              tag = "hl0.57.0";
              hash = "sha256-9qAw3Xsa0xN9b5ERiWEGL1fBq37GLskcrBj/6ax8PU4=";
            };
          });
        };

      opencode =
        if prev.opencode.version == "2.2.5" then
          prev.opencode.overrideAttrs (old: {
            node_modules = old.node_modules.overrideAttrs (_: {
              outputHash =
                "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
            });
          })
        else
          prev.opencode;
      })
  ];
}
