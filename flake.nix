{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:notashelf/nvf/v0.8";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      plasma-manager,
      nvf,
      hyprland,
      hyprland-plugins,
      ...
    }@inputs:
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
      sharedPkgsModule =
        { ... }:
        {
          nixpkgs.pkgs = pkgs;
        };
    in
    {
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
          specialArgs = { inherit inputs; };
          modules = [
            sharedPkgsModule
            ./hosts/desktop
            ./system/common.nix
            ./system/gui.nix
            ./system/sddm
            ./system/n8n.nix
            ./system/cuda.nix
          ];
        };

        vm = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            sharedPkgsModule
            ./hosts/vm
            ./system/common.nix
            ./system/gui.nix
            ./system/sddm
            ./system/n8n.nix
          ];
        };
      };

      homeConfigurations.gustl = home-manager.lib.homeManagerConfiguration {
        inherit pkgs; # HM reuses the same pkgs (with allowUnfree)
        extraSpecialArgs = { inherit inputs; };
        modules = [
          plasma-manager.homeModules.plasma-manager
          nvf.homeManagerModules.default
          ./home/common.nix
        ];
      };
    };
}
