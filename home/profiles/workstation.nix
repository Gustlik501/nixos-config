{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blender
    lmms
    ppsspp
    beekeeper-studio
    onlyoffice-desktopeditors
  ];
}
