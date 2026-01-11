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
          name = "Home";
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "calendar";
                }
                {
                  type = "weather";
                  location = "Berlin, Germany";
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  search-engine = "google";
                }
                {
                  type = "group";
                  name = "Media";
                  widgets = [
                    {
                      type = "bookmark";
                      title = "Jellyfin";
                      url = "http://jellyfin.local";
                    }
                    {
                      type = "bookmark";
                      title = "Sonarr";
                      url = "http://sonarr.local";
                    }
                    {
                      type = "bookmark";
                      title = "Radarr";
                      url = "http://radarr.local";
                    }
                  ];
                }
                {
                  type = "group";
                  name = "Social";
                  widgets = [
                    {
                      type = "bookmark";
                      title = "Reddit";
                      url = "https://reddit.com";
                    }
                    {
                      type = "bookmark";
                      title = "GitHub";
                      url = "https://github.com";
                    }
                    {
                      type = "bookmark";
                      title = "YouTube";
                      url = "https://youtube.com";
                    }
                  ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "rss";
                  title = "Hacker News";
                  limit = 5;
                  url = "https://news.ycombinator.com/rss";
                }
              ];
            }
          ];
        }
        {
          name = "Infrastructure";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "monitor";
                  title = "Frodo Server";
                  url = "http://192.168.1.64:8080";
                }
                {
                  type = "monitor";
                  title = "Internet Connectivity";
                  url = "https://google.com";
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
