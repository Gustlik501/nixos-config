{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blender
    lmms
    ppsspp
    # Disabled: nixpkgs marks Beekeeper 6.1.4 insecure (bundled EOL Electron 39).
    # DBeaver remains available through the shared PC profile.
    # beekeeper-studio
    onlyoffice-desktopeditors
  ];
}
