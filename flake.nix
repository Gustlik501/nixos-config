{
  description = "My system configuration";

  # llm-agents.nix publishes its packages here. Input flake settings are not
  # inherited automatically, so declare the cache on the top-level flake.
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
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
          permittedInsecurePackages = [
            "electron-39.8.10"
          ];
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

      nixosConfigurations = {
        laptop = mkHost {
          hostPath = ./hosts/laptop;
          hmImports = hmBaseImports ++ hmPcImports;
        };

        desktop = mkHost {
          hostPath = ./hosts/desktop;
          hmImports = hmBaseImports ++ hmPcImports ++ hmWorkstationImports;
        };

        frodo = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs;
          modules = [
            sharedPkgsModule
            sops-nix.nixosModules.sops
            disko.nixosModules.disko
            inputs.hermes-agent.nixosModules.default
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
          nixos-rebuild switch \
            --flake "$root#frodo" \
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
          nixos-rebuild boot \
            --flake "$root#frodo" \
            --target-host "$target" \
            --sudo \
            --ask-sudo-password \
            "$@"
        '';
      };
    };
}
