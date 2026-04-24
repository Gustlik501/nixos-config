{ pkgs, config, ... }:

let
  defaultWallpaper = "${config.xdg.dataHome}/nixos/wallpapers/wallhaven-k83or7.jpg";
in
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        defaultWallpaper
      ];
      wallpaper = [
        # Apply to all monitors. Remove the monitor name to apply to all.
        ",${defaultWallpaper}"
      ];
    };
  };
}
