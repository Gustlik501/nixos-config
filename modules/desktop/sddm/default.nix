{ pkgs, ... }:
{
  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;

    theme = "dog-samurai";
    extraPackages = with pkgs; [
      qylockSddmDogSamuraiTheme
      qt6.qt5compat
      qt6.qtdeclarative
      qt6.qtmultimedia
      qt6.qtsvg
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
    ];
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

  environment.systemPackages = with pkgs; [
    kdePackages.breeze
    qylockSddmDogSamuraiTheme
  ];
}
