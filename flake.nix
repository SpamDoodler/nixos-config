# /etc/nixos/flake.nix
{
  description = "flake for NixSama";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosConfigurations = {
      NixSama = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
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
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.spamdoodler = import ./home/spamdoodler.nix;
          }
        ];
      };
    };
    formatter.${system} = pkgs.alejandra;

    devShells.${system}.ai-supercollider = pkgs.mkShell {
      packages = [pkgs.supercollider];
      shellHook = ''
        echo "AI + SuperCollider workspace"
        echo "Run: sclang projects/ai-supercollider/sessions/01-first-sound.scd"
      '';
    };
  };
}
