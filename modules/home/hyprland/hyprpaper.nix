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
        # Apply to all monitors. Remove the monitor name to apply to all.
        ",/home/gustl/nixos-config/wallpapers/dark.png"
      ];
    };
  };
}
