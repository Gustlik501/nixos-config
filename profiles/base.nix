{
  config,
  inputs,
  lib,
  pkgs,
  username,
  userFullName,
  ...
}:
{
  # Core Network Manager
  networking.networkmanager.enable = true;

  # Basic Locale & Time
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

  # Nix Settings
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "root"
    username
  ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = lib.mkDefault (
      inputs.self + "/secrets/${config.networking.hostName}/secrets.yaml"
    );
    defaultSopsFormat = lib.mkDefault "yaml";
    secrets.ssh_user_ed25519_key = {
      path = "/home/${username}/.ssh/id_ed25519";
      owner = username;
      group = username;
      mode = "0600";
    };
  };
  systemd.tmpfiles.rules = [
    "d /home/${username}/.ssh 0700 ${username} ${username} -"
  ];

  # User Configuration
  users.users.${username} = {
    isNormalUser = true;
    description = userFullName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  # Essential Packages
  environment.systemPackages = with pkgs; [
    vim
    git
    home-manager
    btop
    age
    sops
  ];

  programs.zsh.enable = true;

  system.stateVersion = "26.05";
}
