{ ... }:
let repoWp = builtins.toString (../../wallpapers);
in {
  xdg.configFile."kdeglobals" = {
    text = ''
      [General]
      ColorScheme=BreezeDark
    '';
    force = true;
  };

  home.file.".local/share/wallpapers/dark.png".source = "${repoWp}/dark.png";

  xdg.configFile."plasma-org.kde.plasma.desktop-appletsrc" = {
    source = ./plasma-appletsrc;
    force  = true;
  };
}
