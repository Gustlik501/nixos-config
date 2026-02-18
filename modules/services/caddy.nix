{ config, pkgs, ... }:

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
