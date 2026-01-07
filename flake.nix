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

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher-cracked = {
      url = "github:Diegiwg/PrismLauncher-Cracked";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cinecli = {
      url = "github:eyeblech/cinecli";
      inputs.nixpkgs.follows = "nixpkgs";
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
      username = "gustl";
      userFullName = "Gregor Sevcnikar";
      userEmail = "sevcnikar.gregor2@gmail.com";
      gitUsername = "Gustlik501";
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
          specialArgs = { inherit inputs username userFullName userEmail gitUsername; };
          modules = [
            sharedPkgsModule
            ./hosts/laptop
            ./system/common.nix
            ./system/gui.nix
            ./system/sddm
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs username userFullName userEmail gitUsername; };
              home-manager.users.${username} = {
                imports = [
                  plasma-manager.homeModules.plasma-manager
                  nvf.homeManagerModules.default
                  ./home/common.nix
                ];
              };
            }
          ];
        };

        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username userFullName userEmail gitUsername; };
          modules = [
            sharedPkgsModule
            ./hosts/desktop
            ./system/common.nix
            ./system/gui.nix
            ./system/sddm
            ./system/n8n.nix
            ./system/cuda.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs username userFullName userEmail gitUsername; };
              home-manager.users.${username} = {
                imports = [
                  plasma-manager.homeModules.plasma-manager
                  nvf.homeManagerModules.default
                  ./home/common.nix
                ];
              };
            }
          ];
        };

        vm = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username userFullName userEmail gitUsername; };
          modules = [
            sharedPkgsModule
            ./hosts/vm
            ./system/common.nix
            ./system/gui.nix
            ./system/sddm
            ./system/n8n.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs username userFullName userEmail gitUsername; };
              home-manager.users.${username} = {
                imports = [
                  plasma-manager.homeModules.plasma-manager
                  nvf.homeManagerModules.default
                  ./home/common.nix
                ];
              };
            }
          ];
        };
      };
    };
}
