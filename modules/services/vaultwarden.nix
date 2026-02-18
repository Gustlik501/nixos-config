{ config, pkgs, ... }:

{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://vault.frodo.local";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = true;
      DATA_FOLDER = "/data/vaultwarden";
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/vaultwarden 0700 vaultwarden vaultwarden -"
  ];

  systemd.services.vaultwarden.serviceConfig = {
    ReadWritePaths = [ "/data/vaultwarden" ];
  };
}
