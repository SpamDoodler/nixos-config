# /etc/nixos/flake.nix
{
  description = "flake for NixSama";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/v0.54.2";
    };
    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.54.2"; # where {version} is the hyprland release version
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    hy3,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosConfigurations = {
      NixSama = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        # system = "x86_64-linux";
        modules = [
          ./hardware/hardware.nix
          ./system/system.nix
          ./fonts/fonts.nix
          ./users/users.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.spamdoodler = import ./home/spamdoodler.nix;
          }
        ];
      };
    };
    formatter.${system} = pkgs.alejandra;
  };
}
