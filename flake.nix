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

    checks.${system} = let
      # Exercise desktop scripts with the same overlays as the actual host.
      hostPkgs = self.nixosConfigurations.NixSama.pkgs;
      lib = nixpkgs.lib;
      renderRtw89 = settings:
        (lib.evalModules {
          modules = [
            ./hardware/custom-rtw89.nix
            {
              options.boot.kernelModules = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
              };
              options.boot.kernelParams = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [];
              };
              config.hardware = settings;
            }
          ];
        }).config.boot;
      defaults = renderRtw89 {enableRtw89Pci = true;};
      disabled = renderRtw89 {enableRtw89Pci = false;};
      mixed = renderRtw89 {
        enableRtw89Pci = true;
        rtw89PciOptions = {
          disable_clkreq = false;
          disable_aspm_l1 = true;
          disable_aspm_l1ss = false;
        };
      };
    in {
      desktop-scripts = import ./tests/desktop-scripts.nix {pkgs = hostPkgs;};
      rtw89-options = assert defaults.kernelModules == ["rtw89_pci"];
      assert defaults.kernelParams
      == [
        "rtw89_pci.disable_clkreq=1"
        "rtw89_pci.disable_aspm_l1=1"
        "rtw89_pci.disable_aspm_l1ss=1"
      ];
      assert disabled.kernelModules == [] && disabled.kernelParams == [];
      assert mixed.kernelParams
      == [
        "rtw89_pci.disable_clkreq=0"
        "rtw89_pci.disable_aspm_l1=1"
        "rtw89_pci.disable_aspm_l1ss=0"
      ];
        pkgs.runCommand "rtw89-option-tests" {} "touch $out";
    };

    devShells.${system}.ai-supercollider = pkgs.mkShell {
      packages = [pkgs.supercollider pkgs.pipewire.jack];
      shellHook = ''
        echo "AI + SuperCollider workspace"
        echo "Run: pw-jack sclang projects/ai-supercollider/sessions/01-first-sound.scd"
      '';
    };
  };
}
