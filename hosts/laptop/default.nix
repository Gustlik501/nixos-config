{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
    ];
  };

  boot.initrd.kernelModules = [ "i915" ];

}
