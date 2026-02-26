{pkgs, ...}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    themeConfig = {
      AccentColor = "#746385";
      FormPosition = "left";

      ForceHideCompletePassword = true;
    };
    embeddedTheme = "japanese_aesthetic";
  };
in {
  services.displayManager.sddm = {
    enable = true;
    #package = pkgs.kdePackages.sddm; # qt6 sddm version

    theme = "sddm-astronaut-theme";
    extraPackages = [sddm-astronaut];
    settings.Theme = {
      CursorTheme = "breeze_cursors";
      CursorSize = 24;
    };

    wayland = {
      enable = true;
      # Plasma previously set this implicitly; keep it explicit after removing Plasma.
      compositor = "kwin";
    };
  };

  environment.systemPackages = [
    sddm-astronaut
    pkgs.kdePackages.breeze
  ];
}
