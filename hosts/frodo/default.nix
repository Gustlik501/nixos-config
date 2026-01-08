{ config, pkgs, username, ... }:
{
  imports = [
    ./disk-config.nix
    ../../system/core.nix
  ];

  networking.hostName = "frodo";
  networking.hostId = "8425e349"; # Required for ZFS

  nixpkgs.config.allowUnfree = true;

  # ZFS: Add nofail so system doesn't panic if pools are slow
  fileSystems."/data" = {
    device = "dpool";
    fsType = "zfs";
    options = [ "zfsutil" "nofail" ];
  };

  fileSystems."/media" = {
    device = "mpool";
    fsType = "zfs";
    options = [ "zfsutil" "nofail" ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # ZFS Support
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # SSH is essential for a headless server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Change to false once you've added your SSH key
    };
  };

  # NVIDIA 1050ti configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # 1050ti is too old for the open kernel modules
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable Container/Docker support (useful for homelabs)
  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = [ "docker" ];

  # Basic Server Tools
  environment.systemPackages = with pkgs; [
    wget
    curl
    pciutils
    glances
    kitty.terminfo # Fixes "xterm-kitty" error when SSHing from Kitty
    # Add any other server-specific tools here (e.g., iotop, ncdu)
  ];

  # Firewall settings for common services
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
  };

  system.stateVersion = "25.11";
}
