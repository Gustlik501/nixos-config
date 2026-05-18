{ config, pkgs, ... }:

let
  proxyHost =
    port:
    {
      extraConfig = ''
        tls internal
        encode zstd gzip
        reverse_proxy :${toString port}
      '';
    };
in
{

  services.caddy = {
    enable = true;

    virtualHosts = {
      # CASE A: The Root Domain -> Port 8080 (e.g. Glance)
      "frodo.local" = {
        extraConfig = ''
          tls internal
          reverse_proxy :8080
        '';
      };

      "glance.frodo.local" = proxyHost 8080;

      "seerr.frodo.local" = proxyHost 5055;
      "jelly.frodo.local" = proxyHost 8096;
      "sonarr.frodo.local" = proxyHost 8989;
      "radarr.frodo.local" = proxyHost 7878;
      "bazarr.frodo.local" = proxyHost 6767;
      "lidarr.frodo.local" = proxyHost 8686;
      "prowlarr.frodo.local" = proxyHost 9696;
      "profilarr.frodo.local" = proxyHost 5678;
      "qbit.frodo.local" = proxyHost 8081;
      "adguard.frodo.local" = proxyHost 3000;
      "hermes.frodo.local" = proxyHost 8644;

      # CASE B: The Subdomain -> Port 8222 (Vaultwarden)
      "vault.frodo.local" = {
        extraConfig = ''
          tls internal
          encode zstd gzip
          reverse_proxy :${toString config.services.vaultwarden.config.ROCKET_PORT} {
             header_up X-Real-IP {remote_host}
          }
        '';
      };
    };
  };
}
