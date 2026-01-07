{
  config,
  pkgs,
  username,
  userFullName,
  ...
}:
{

  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.bluetooth.settings = {
    General = {
      ControllerMode = "dual";
      JustWorksRepairing = "always";
      PairableTimeout = 0;
      DiscoverableTimeout = 0;
      Agent = "KeyboardDisplay";
    };
  };

  services = {
    blueman.enable = true;
    upower.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    tumbler.enable = true;
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true; # Optional, for JACK support
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  time.timeZone = "Europe/Ljubljana";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sl_SI.UTF-8";
    LC_IDENTIFICATION = "sl_SI.UTF-8";
    LC_MEASUREMENT = "sl_SI.UTF-8";
    LC_MONETARY = "sl_SI.UTF-8";
    LC_NAME = "sl_SI.UTF-8";
    LC_NUMERIC = "sl_SI.UTF-8";
    LC_PAPER = "sl_SI.UTF-8";
    LC_TELEPHONE = "sl_SI.UTF-8";
    LC_TIME = "sl_SI.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us,si";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.${username} = {
    isNormalUser = true;
    description = userFullName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  nix.settings.trusted-users = [
    "root"
    username
  ];

  environment.systemPackages = with pkgs; [
    vim
    home-manager
    #steam
    nerd-fonts.jetbrains-mono
    networkmanagerapplet
    #gparted
    kdePackages.partitionmanager
  ];

  #programs.steam.enable = true;
  programs.zsh.enable = true;

  system.stateVersion = "25.05";
}
