{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations = {
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/laptop
            ./modules/system/common.nix
            ./modules/system/gui.nix
            ./modules/system/sddm
          ];
        };
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/desktop
            ./modules/system/common.nix
            ./modules/system/gui.nix
            ./modules/system/sddm
          ];
        };
      };

      homeConfigurations.gustl = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home/common.nix ];
      };
    };
}
