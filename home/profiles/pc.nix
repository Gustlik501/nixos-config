{
  config,
  pkgs,
  userEmail,
  gitUsername,
  ...
}:
let
  quake3eWrapped = pkgs.symlinkJoin {
    name = "quake3e-wrapped";
    paths = [ pkgs.quake3e ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/quake3e \
        --set SDL_VIDEODRIVER x11 \
        --set SDL_VIDEO_FULLSCREEN_DISPLAY 0
    '';
  };
in
{
  imports = [
    ../hyprland
    ../qylock
    ../kitty
    ../rofi
    ../firefox
    ../vesktop
    ../gtk
    ../noctalia
    ../cwal
  ];

  xdg.configFile = {
    "hypr/nixos/UserKeybinds.conf".source = ../hyprland/configs/UserKeybinds.conf;
    "hypr/nixos/WindowRules.conf".source = ../hyprland/configs/WindowRules.conf;
    "hypr/nixos/UserDecorations.conf".source = ../hyprland/configs/UserDecorations.conf;
    "hypr/nixos/Monitors.conf".source = ../hyprland/configs/Monitors.conf;
    "hypr/nixos/Monitors.desktop.conf".source = ../hyprland/configs/Monitors.desktop.conf;
    "hypr/nixos/Monitors.laptop.conf".source = ../hyprland/configs/Monitors.laptop.conf;
    "hypr/nixos/default.conf".source = ../hyprland/configs/default.conf;
    "rofi/nixos".source = ../../cfgs/rofi;
  };

  xdg.dataFile."nixos/wallpapers".source = ../../wallpapers;

  home.file = {
    ".local/bin/bgselector" = {
      source = ../../scripts/bgselector.sh;
      executable = true;
    };
    ".local/bin/clipboard" = {
      source = ../../scripts/clipboard.sh;
      executable = true;
    };
    ".local/bin/cwal-theme-selector" = {
      source = ../../scripts/cwal-theme-selector.sh;
      executable = true;
    };
    ".local/bin/display-keybinds" = {
      source = ../../scripts/display-keybinds.sh;
      executable = true;
    };
    ".local/bin/powermenu" = {
      source = ../../scripts/powermenu.sh;
      executable = true;
    };
  };

  home.packages = with pkgs; [
    nodejs
    openssh
    runelite
    vlc
    dart-sass
    wl-clipboard
    gtksourceview3
    libsoup_3
    libgtop
    bolt-launcher

    deluge
    gimp
    obsidian
    grimblast
    cliphist

    #lutris
    wineWow64Packages.stagingFull
    winetricks

    bluez-tools
    vulkan-tools
    pciutils
    mesa-demos
    foliate
    localsend
    sqlitebrowser

    #logitech mouse
    #solaar

    telegram-desktop
    devenv

    freerdp

    remmina
    openconnect
    dbeaver-bin
    bitwarden-desktop
    google-chrome

    bruno

    #bambu-studio
    cinny-desktop
    quake3eWrapped
  ];

  programs.git = {
    enable = true;
    settings.user.email = userEmail;
    settings.user.name = gitUsername;
    lfs.enable = true;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.sessionVariables.TERMINAL = "kitty";

  # Make Thunar the default file manager
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
      "application/x-directory" = [ "thunar.desktop" ];
      "x-scheme-handler/terminal" = "kitty.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
