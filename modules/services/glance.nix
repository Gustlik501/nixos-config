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
                { type = "calendar"; }
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
                  type = "bookmarks";
                  groups = [
                    {
                      title = "Media";
                      links = [
                        {
                          title = "Jellyfin";
                          url = "http://jellyfin.local";
                        }
                        {
                          title = "Sonarr";
                          url = "http://sonarr.local";
                        }
                        {
                          title = "Radarr";
                          url = "http://radarr.local";
                        }
                      ];
                    }
                    {
                      title = "Social";
                      links = [
                        {
                          title = "Reddit";
                          url = "https://reddit.com";
                        }
                        {
                          title = "GitHub";
                          url = "https://github.com";
                        }
                        {
                          title = "YouTube";
                          url = "https://youtube.com";
                        }
                      ];
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