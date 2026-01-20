{
  config,
  pkgs,
  inputs,
  username,
  userEmail,
  gitUsername,
  ...
}:
{

  imports = [
    ./hyprland
    ./kitty
    ./rofi
    ./btop
    ./zsh
    ./gtk
    ./nvf
    ./noctalia
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";

    packages = with pkgs; [
      nodejs
      tree
      git
      git-lfs
      lazygit
      openssh
      curl
      wget
      fastfetch
      btop
      eza
      runelite
      firefox
      vlc
      gemini-cli
      ripgrep
      vesktop
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
      wineWowPackages.stagingFull
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

      #music prod
      ardour
      sfizz
      zynaddsubfx
      helm
      dragonfly-reverb
      calf
      lmms

      #Job
      freerdp
      #rustdesk
      input-leap
      remmina
      openconnect
      dbeaver-bin
      bitwarden-desktop
      google-chrome

      bruno

      inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      lg = "lazygit";
      ls = "eza --icons --group-directories-first";
      ll = "eza -lh --icons --grid --group-directories-first";
      lt = "eza --tree --icons --group-directories-first";
    };
  };

  # programs.neovim = {
  #   enable = true;
  #   defaultEditor = true;
  #   plugins = with pkgs.vimPlugins; [
  #     gruvbox-material
  #     nerdtree
  #   ];
  # };

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
    };
  };

}
