{ pkgs, inputs, osConfig, ... }:
let
  hostName = osConfig.networking.hostName or "";
  monitorsFile =
    if hostName == "desktop" then ./configs/monitors-desktop.lua else
    if hostName == "laptop" then ./configs/monitors-laptop.lua else
    ./configs/monitors-default.lua;
in
{
  imports = [
    (import ./hyprland.nix { inherit pkgs inputs; })
    #./hyprpaper.nix
    ../noctalia
  ];

  # Written to $XDG_CONFIG_HOME/hypr/nixos/*.lua and required from hyprland.lua.
  wayland.windowManager.hyprland.extraLuaFiles = {
    "nixos/autostart" = ./configs/autostart.lua;
    "nixos/decorations" = ./configs/decorations.lua;
    "nixos/input" = ./configs/input.lua;
    "nixos/keybinds" = ./configs/keybinds.lua;
    "nixos/monitors" = monitorsFile;
    "nixos/window-rules" = ./configs/window-rules.lua;
  };
}
