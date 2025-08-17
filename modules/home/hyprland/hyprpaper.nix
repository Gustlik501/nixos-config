{ pkgs, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/gustl/nixos-config/wallpapers/dark.png"
        "/home/gustl/nixos-config/wallpapers/light.png"
      ];
      wallpaper = [
        # You might need to change eDP-1 to your monitor's name
        "eDP-1,/home/gustl/nixos-config/wallpapers/dark.png"
      ];
    };
  };
}
