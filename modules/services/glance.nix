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
                      url = "http://192.168.1.64:8080";
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
                      url = "http://192.168.1.64:5055";
                    }
                    {
                      title = "Jellyfin";
                      url = "http://192.168.1.64:8096";
                    }
                    {
                      title = "Sonarr";
                      url = "http://192.168.1.64:8989";
                    }
                    {
                      title = "Radarr";
                      url = "http://192.168.1.64:7878";
                    }
                    {
                      title = "Bazarr";
                      url = "http://192.168.1.64:6767";
                    }
                    {
                      title = "Lidarr";
                      url = "http://192.168.1.64:8686";
                    }
                    {
                      title = "Prowlarr";
                      url = "http://192.168.1.64:9696";
                    }
                    {
                      title = "Profilarr";
                      url = "http://192.168.1.64:5678";
                    }
                    {
                      title = "qBittorrent";
                      url = "http://192.168.1.64:8081";
                    }
                    {
                      title = "VaultWarden";
                      url = "https://vault.frodo.local";
                    }
                    {
                      title = "AdGuard";
                      url = "http://192.168.1.64:3000";
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
