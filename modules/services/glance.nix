{ ... }:

{
  services.glance = {
    enable = true;
    settings = {
      server = {
        port = 8080;
        host = "0.0.0.0";
      };
      pages = [
        {
          name = "Media";
          columns = [
            {
              size = "small";
              widgets = [
                { type = "server-stats"; }
                {
                  type = "monitor";
                  title = "Status";
                  cache = "1m";
                  style = "compact";
                  sites = [
                    {
                      title = "Router";
                      url = "http://192.168.1.254";
                      timeout = "10s";
                    }
                    {
                      title = "Frodo";
                      url = "https://frodo.local";
                      check-url = "http://127.0.0.1:8080";
                    }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "monitor";
                  title = "Services";
                  cache = "1m";
                  sites = [
                    {
                      title = "Jellyseerr";
                      url = "https://seerr.frodo.local";
                      check-url = "http://127.0.0.1:5055";
                    }
                    {
                      title = "Jellyfin";
                      url = "https://jelly.frodo.local";
                      check-url = "http://127.0.0.1:8096";
                    }
                    {
                      title = "Sonarr";
                      url = "https://sonarr.frodo.local";
                      check-url = "http://127.0.0.1:8989";
                    }
                    {
                      title = "Radarr";
                      url = "https://radarr.frodo.local";
                      check-url = "http://127.0.0.1:7878";
                    }
                    {
                      title = "Bazarr";
                      url = "https://bazarr.frodo.local";
                      check-url = "http://127.0.0.1:6767";
                    }
                    {
                      title = "Lidarr";
                      url = "https://lidarr.frodo.local";
                      check-url = "http://127.0.0.1:8686";
                    }
                    {
                      title = "Prowlarr";
                      url = "https://prowlarr.frodo.local";
                      check-url = "http://127.0.0.1:9696";
                    }
                    {
                      title = "Profilarr";
                      url = "https://profilarr.frodo.local";
                      check-url = "http://127.0.0.1:5678";
                    }
                    {
                      title = "qBittorrent";
                      url = "https://qbit.frodo.local";
                      check-url = "http://127.0.0.1:8081";
                    }
                    {
                      title = "VaultWarden";
                      url = "https://vault.frodo.local";
                      check-url = "http://127.0.0.1:8222";
                    }
                    {
                      title = "AdGuard";
                      url = "https://adguard.frodo.local";
                      check-url = "http://127.0.0.1:3000";
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
