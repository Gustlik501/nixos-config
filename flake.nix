{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:notashelf/nvf";

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    cwal-nvim = {
      url = "github:nitinbhat972/cwal.nvim";
      flake = false;
    };

    zmpl-vim = {
      url = "github:jetzig-framework/zmpl.vim";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nvf,
      disko,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      hmStateVersion = "26.05";
      username = "gustl";
      userFullName = "Gregor Sevcnikar";
      userEmail = "sevcnikar.gregor2@gmail.com";
      gitUsername = "Gustlik501";
      overlays = [
        (
          final: prev:
          let
            qylock = prev.callPackage ./pkgs/qylock.nix { };
          in
          {
            cwal = prev.callPackage ./pkgs/cwal.nix { };
            qylockAssets = qylock.assets;
            qylockSddmDogSamuraiTheme = qylock.sddmDogSamuraiTheme;
          }
        )
      ];
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          # Do not bypass nixpkgs' checks for end-of-life Electron packages.
          permittedInsecurePackages = [ ];
        };
        inherit overlays;
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

      mkApp = name: text: {
        type = "app";
        program = "${pkgs.writeShellScriptBin name text}/bin/${name}";
      };

      mkHomeManagerModule = hmImports: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = commonSpecialArgs;
        home-manager.users.${username} = {
          imports = hmImports;
          home.stateVersion = hmStateVersion;
        };
      };

      mkHost =
        {
          hostPath,
          extraModules ? [ ],
          hmImports ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules = [
            sharedPkgsModule
            sops-nix.nixosModules.sops
            hostPath
            ./profiles/workstation.nix
          ]
          ++ extraModules
          ++ [
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule hmImports)
          ];
        };

      hmBaseImports = [
        nvf.homeManagerModules.default
        ./home/profiles/base.nix
      ];

      hmPcImports = [
        ./home/profiles/pc.nix
      ];

      hmWorkstationImports = [ ./home/profiles/workstation.nix ];
    in
    {
      overlays.default = builtins.head overlays;
      packages.${system}.pi-web = pkgs.callPackage ./pkgs/pi-web.nix { };

      nixosConfigurations = {
        laptop = mkHost {
          hostPath = ./hosts/laptop;
          extraModules = [ ./modules/services/pi-web-workstation.nix ];
          hmImports = hmBaseImports ++ hmPcImports;
        };

        desktop = mkHost {
          hostPath = ./hosts/desktop;
          extraModules = [ ./modules/services/pi-web-workstation.nix ];
          hmImports = hmBaseImports ++ hmPcImports ++ hmWorkstationImports;
        };

        frodo = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules = [
            sharedPkgsModule
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            ./hosts/frodo/default.nix
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule hmBaseImports)
          ];
        };
      };

      apps.${system} = {
        update = mkApp "update" ''
          set -euo pipefail

          root="$PWD"
          if [ ! -f "$root/flake.nix" ]; then
            echo "Run from repo root (flake.nix not found)." >&2
            exit 1
          fi

          nix flake update
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

          target="''${FRODO_HOST:-gustl@frodo.local}"
          # Build on Frodo: untrusted SSH users cannot import unsigned local
          # build outputs. Source/derivations are transferred instead.
          nixos-rebuild switch \
            --flake "$root#frodo" \
            --build-host "$target" \
            --target-host "$target" \
            --sudo \
            --ask-sudo-password \
            "$@"
        '';

        rebuild-frodo-boot = mkApp "rebuild-frodo-boot" ''
          set -euo pipefail

          root="$PWD"
          if [ ! -f "$root/flake.nix" ]; then
            echo "Run from repo root (flake.nix not found)." >&2
            exit 1
          fi

          target="''${FRODO_HOST:-gustl@frodo.local}"
          # Keep build and target hosts identical to avoid unsigned closure
          # imports; sudo is still required only for administrative activation.
          nixos-rebuild boot \
            --flake "$root#frodo" \
            --build-host "$target" \
            --target-host "$target" \
            --sudo \
            --ask-sudo-password \
            "$@"
        '';
      };
    };
}
