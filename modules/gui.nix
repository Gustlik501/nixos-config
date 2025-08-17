{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    steam
  ];

  programs.steam.enable = true;
}
