{
  description = "Frodo Server Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "gustl";
      userFullName = "Gregor Sevcnikar";
    in
    {
      nixosConfigurations.frodo = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username userFullName; };
        modules = [
          disko.nixosModules.disko
          ./default.nix
        ];
      };
    };
}
