{ pkgs, config, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "${config.home.homeDirectory}/nixos-config/wallpapers/dark.png"
        "${config.home.homeDirectory}/nixos-config/wallpapers/light.png"
      ];
      wallpaper = [
        # Apply to all monitors. Remove the monitor name to apply to all.
        ",${config.home.homeDirectory}/nixos-config/wallpapers/dark.png"
      ];
    };
  };
}
