{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  boot.kernelParams = [
    "quiet"
    "splash"
    "video=1920x1080@60"
  ];

  virtualisation.hypervGuest.enable = true;
  networking.hostName = "nixos-vm";

  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
    ];
  };

  # Your user to groups
  users.users.gustl.extraGroups = [
  ];

  # Handy tools/ISOs available on host
  environment.systemPackages = with pkgs; [
  ];

}
