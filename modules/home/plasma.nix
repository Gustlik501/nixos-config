{ ... }:
let repoWp = builtins.toString (../../wallpapers);
in {
  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark
  '';
  home.file.".local/share/wallpapers/dark.png".source = "${repoWp}/dark.png";
  xdg.configFile."plasma-org.kde.plasma.desktop-appletsrc".source =
    ../modules/home/plasma-appletsrc;
}
