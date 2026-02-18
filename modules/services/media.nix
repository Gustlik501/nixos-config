{ pkgs, lib, ... }:

{
  # --------------------------------------------------------------------------------------
  # Media Group & Permissions
  # --------------------------------------------------------------------------------------
  users.groups.media = { };

  # Prowlarr doesn't have a 'services.prowlarr.group' option, so we must
  # manually configure its user to be part of the 'media' group.
  users.groups.prowlarr = { };
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "media" ];
  };

  # For others, we'll use the service-specific group option where available,
  # but also ensure the users exist in the media group for the folders.
  users.users.gustl.extraGroups = [ "media" ];

  # Automate directory creation and permissions
  systemd.tmpfiles.rules = [
    "d /media/torrents 0775 gustl media -"
    "d /media/movies   0775 gustl media -"
    "d /media/shows    0775 gustl media -"
    "d /media/music    0775 gustl media -"
  ];

  # --------------------------------------------------------------------------------------
  # Services
  # --------------------------------------------------------------------------------------

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  
  systemd.services.qbittorrent.serviceConfig = {
    BindPaths = [ "/media" ];
    UMask = lib.mkForce "0002";
    StateDirectory = "qbittorrent";
    WorkingDirectory = "/var/lib/qbittorrent";
    Environment = "HOME=/var/lib/qbittorrent";
    ExecStart = lib.mkForce "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8081";
  };

  # Open qBittorrent ports
  networking.firewall = {
    allowedTCPPorts = [ 6881 6882 8081 ];
    allowedUDPPorts = [ 6881 6882 ];
  };

  services.prowlarr.enable = true;
  services.prowlarr.openFirewall = true;

  services.sonarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  systemd.services.sonarr.serviceConfig = {
    BindPaths = [ "/media" ];
    UMask = lib.mkForce "0002";
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  systemd.services.radarr.serviceConfig = {
    BindPaths = [ "/media" ];
    UMask = lib.mkForce "0002";
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  systemd.services.bazarr.serviceConfig = {
    BindPaths = [ "/media" ];
    UMask = lib.mkForce "0002";
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  systemd.services.lidarr.serviceConfig = {
    BindPaths = [ "/media" ];
    UMask = lib.mkForce "0002";
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
}
