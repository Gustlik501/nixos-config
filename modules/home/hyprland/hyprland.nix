{ pkgs, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      "exec-once" = [
        "hyprpaper"
      ];
    };
  };
}
