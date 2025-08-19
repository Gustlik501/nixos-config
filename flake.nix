{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:notashelf/nvf";
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, nvf, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        # permittedInsecurePackages = [];  # add if needed
      };
    };

    # Tiny helper to ensure NixOS also uses the same pkgs
    sharedPkgsModule = { ... }: { nixpkgs.pkgs = pkgs; };
  in {
    nixosConfigurations = {
      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          sharedPkgsModule
          ./hosts/laptop
          ./system/common.nix
          ./system/gui.nix
          ./system/sddm
        ];
      };

      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          sharedPkgsModule
          ./hosts/desktop
          ./system/common.nix
          ./system/gui.nix
          ./system/sddm
        ];
      };
    };

    homeConfigurations.gustl = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;  # HM reuses the same pkgs (with allowUnfree)
      modules = [
        plasma-manager.homeManagerModules.plasma-manager
        nvf.homeManagerModules.default
        ./home/common.nix
      ];
    };
  };
}
