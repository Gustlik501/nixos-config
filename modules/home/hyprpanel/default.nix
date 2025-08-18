{ inputs, pkgs, ... }:

{
  # HyprPanel itself
  programs.hyprpanel = {
    enable = true;

    # If you want to pin dev version from HyprPanel flake
    # package = inputs.hyprpanel.packages.${pkgs.system}.default;

    settings = {
      layout = {
        bar.layouts = {
          "0" = {
            left = [ "dashboard" "workspaces" ];
            middle = [ "media" ];
            right = [ "volume" "systray" "notifications" ];
          };
        };
      };

      bar.launcher.autoDetectIcon = true;
      bar.workspaces.show_icons = true;

      menus.clock = {
        time.military = true;
        time.hideSeconds = true;
        weather.unit = "metric";
      };

      menus.dashboard.directories.enabled = false;
      menus.dashboard.stats.enable_gpu = true;

      theme.bar.transparent = true;
      theme.font = {
        name = "CaskaydiaCove NF";
        size = "16px";
      };
    };
  };
}
