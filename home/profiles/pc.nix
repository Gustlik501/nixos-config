{
  config,
  pkgs,
  inputs,
  userEmail,
  gitUsername,
  ...
}:
{
  imports = [
    ../hyprland
    ../hyprlock
    ../kitty
    ../rofi
    ../gtk
    ../noctalia
  ];

  home.packages = with pkgs; [
    nodejs
    openssh
    runelite
    firefox
    vlc
    gemini-cli
    vesktop
    dart-sass
    wl-clipboard
    gtksourceview3
    libsoup_3
    libgtop
    bolt-launcher
    codex

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
    solaar

    telegram-desktop
    devenv

    freerdp

    remmina
    openconnect
    dbeaver-bin
    bitwarden-desktop
    google-chrome

    bruno

    bambu-studio
    hub

    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
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
