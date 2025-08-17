{ pkgs, ... }:
let repoWp = builtins.toString (../../wallpapers);
in {
   xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
  '';

  # ensure the tools exist
  home.packages = [
    pkgs.kdePackages.plasma-workspace
    pkgs.kdePackages.breeze-gtk
  ];

  # (optional) make GTK apps dark too
  gtk.enable = true;
  gtk.theme.name = "Breeze-Dark";
  xdg.configFile."gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-application-prefer-dark-theme=1
  '';

  home.file.".local/share/wallpapers/dark.png".source = "${repoWp}/dark.png";

  xdg.configFile."plasma-org.kde.plasma.desktop-appletsrc" = {
    source = ./plasma-appletsrc;
    force  = true;
  };
}
