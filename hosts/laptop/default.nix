{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-sdk
    ];
  };

  hardware.graphics.extraPackages = with pkgs; [ vaapiIntel intel-media-driver ];

}
