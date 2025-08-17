{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    firefox
    kde-gruvbox
    steam
    vlc
  ];

  programs.steam.enable = true;
}
