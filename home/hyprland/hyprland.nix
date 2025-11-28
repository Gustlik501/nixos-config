{ pkgs, inputs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    plugins = [
      inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.csgo-vulkan-fix
    ];
    settings = {
      "exec-once" = [
        #"swww img /home/gustl/nixos-config/wallpapers/dark.png"
        "hyprpaper"
        "hyprpanel" # Add waybar here
        "swww-daemon"
        #"waybar"
      ];
      plugin = {
        csgo-vulkan-fix = {
          res = "1920x1080";
        };
      };
    };
  };
}
