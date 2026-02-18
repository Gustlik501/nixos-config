{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blender
    lmms
  ];
}
