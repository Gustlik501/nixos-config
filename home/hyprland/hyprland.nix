{ pkgs, inputs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    #xwayland.enable = true;
    plugins = [
      # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.csgo-vulkan-fix
    ];
    settings = {
      xwayland = {
        enabled = true;
      };

      "exec-once" = [
        "hyprpaper"
        "noctalia-shell"
        "awww-daemon --quiet"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];
      plugin = {
        #csgo-vulkan-fix = {
        #res = "1920x1080";
        #};
      };
    };
  };
}
