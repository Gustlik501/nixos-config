{
  config,
  pkgs,
  username,
  userFullName,
  ...
}:
{
  imports = [ ./core.nix ];

  # Desktop/Laptop Networking Extras
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  # Bluetooth
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
  services.blueman.enable = true;

  # Power & Storage Services
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;

  # File Manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Portals
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # Keyboard Layout (X11/Wayland)
  services.xserver.xkb = {
    layout = "us,si";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  # Desktop User Extras
  users.users.${username}.extraGroups = [ "audio" ];

  # Desktop Packages
  environment.systemPackages = with pkgs; [
    nerd-fonts.jetbrains-mono
    networkmanagerapplet
    kdePackages.partitionmanager
  ];

  system.stateVersion = "25.11";
}