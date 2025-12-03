{ pkgs, inputs, config, ... }:
{
  imports = [
    (import ./hyprland.nix { inherit pkgs inputs; })
    #./hyprpaper.nix
    #../waybar # Add Waybar module
    ../hyprpanel
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/UserKeybinds.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/WindowRules.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/UserDecorations.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/Monitors.conf
    source = ${config.home.homeDirectory}/nixos-config/home/hyprland/configs/default.conf
  '';
}
