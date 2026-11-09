{
  config,
  pkgs,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Work around the old nixpkgs pairing of hy3 0.56.0.1 with Hyprland 0.57:
      # hy3 fails to compile against hyprutils 0.14.3 (CBox constructors).
      # Newer nixpkgs already ships hl0.57.0; never replace that or later releases.
      # Remove this branch once supporting the affected lock is no longer useful.
      # Verify: nix build --no-link .#nixosConfigurations.NixSama.config.system.build.toplevel
      hyprlandPlugins =
        prev.hyprlandPlugins
        // {
          hy3 =
            if prev.hyprlandPlugins.hy3.version == "0.56.0.1"
            then
              assert prev.lib.versions.majorMinor prev.hyprland.version == "0.57";
                prev.hyprlandPlugins.hy3.overrideAttrs (old: {
                  version = "0.57.0";
                  src = prev.fetchFromGitHub {
                    owner = "outfoxxed";
                    repo = "hy3";
                    tag = "hl0.57.0";
                    hash = "sha256-9qAw3Xsa0xN9b5ERiWEGL1fBq37GLskcrBj/6ax8PU4=";
                  };
                })
            else prev.hyprlandPlugins.hy3;
        };

      opencode =
        if prev.opencode.version == "2.2.5"
        then
          prev.opencode.overrideAttrs (old: {
            node_modules = old.node_modules.overrideAttrs (_: {
              outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
            });
          })
        else prev.opencode;
    })
  ];
}
