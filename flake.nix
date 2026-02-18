{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-frodo.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:notashelf/nvf";

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

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    prismlauncher-cracked = {
      url = "github:Diegiwg/PrismLauncher-Cracked";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-frodo";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      disko,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "gustl";
      userFullName = "Gregor Sevcnikar";
      userEmail = "sevcnikar.gregor2@gmail.com";
      gitUsername = "Gustlik501";
      nixpkgsFrodo = inputs."nixpkgs-frodo";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          # permittedInsecurePackages = [];  # add if needed
        };
        # overlays = [ ];
      };
      pkgsFrodo = import nixpkgsFrodo {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      commonSpecialArgs = {
        inherit
          inputs
          username
          userFullName
          userEmail
          gitUsername
          ;
      };

      mkPkgsModule =
        pkgs':
        { ... }:
        {
          nixpkgs.pkgs = pkgs';
        };

      # Tiny helper to ensure NixOS also uses the same pkgs
      sharedPkgsModule = mkPkgsModule pkgs;
      frodoPkgsModule = mkPkgsModule pkgsFrodo;

      mkApp = name: text: {
        type = "app";
        program = "${pkgs.writeShellScriptBin name text}/bin/${name}";
      };

      mkHost =
        {
          hostPath,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules =
            [
              sharedPkgsModule
              sops-nix.nixosModules.sops
              hostPath
              ./profiles/workstation.nix
            ]
            ++ extraModules
            ++ [
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup";
                home-manager.extraSpecialArgs = commonSpecialArgs;
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
    in
    {
      nixosConfigurations = {
        laptop = mkHost { hostPath = ./hosts/laptop; };

        desktop = mkHost { hostPath = ./hosts/desktop; };

        frodo = nixpkgsFrodo.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules = [
            frodoPkgsModule
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            ./hosts/frodo/default.nix
          ];
        };
      };

      apps.${system} = {
        update-pc = mkApp "update-pc" ''
          set -euo pipefail

          root="$PWD"
          if [ ! -f "$root/flake.nix" ]; then
            echo "Run from repo root (flake.nix not found)." >&2
            exit 1
          fi

          inputs=(
            nixpkgs
            home-manager
            plasma-manager
            nvf
            hyprland
            hyprland-plugins
            antigravity-nix
            noctalia
            prismlauncher-cracked
          )

          nix flake update "''${inputs[@]}"
        '';

        update-frodo = mkApp "update-frodo" ''
          set -euo pipefail

          root="$PWD"
          if [ ! -f "$root/flake.nix" ]; then
            echo "Run from repo root (flake.nix not found)." >&2
            exit 1
          fi

          nix flake update nixpkgs-frodo disko
        '';

        rebuild-pc = mkApp "rebuild-pc" ''
          set -euo pipefail

          root="$PWD"
          if [ ! -f "$root/flake.nix" ]; then
            echo "Run from repo root (flake.nix not found)." >&2
            exit 1
          fi

          host="''${HOST_OVERRIDE:-$(uname -n)}"
          sudo nixos-rebuild switch --flake "$root#''${host}" "$@"
        '';

        rebuild-frodo = mkApp "rebuild-frodo" ''
          set -euo pipefail

          root="$PWD"
          if [ ! -f "$root/flake.nix" ]; then
            echo "Run from repo root (flake.nix not found)." >&2
            exit 1
          fi

          target="''${FRODO_HOST:-gustl@frodo.lan}"
          nixos-rebuild switch \
            --flake "$root#frodo" \
            --target-host "$target" \
            --sudo \
            --ask-sudo-password \
            "$@"
        '';
      };
    };
}
