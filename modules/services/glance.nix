{ ... }:

{
  services.glance = {
    enable = true;
    settings = {
      server.port = 8080;
      pages = [
        {
          name = "Homelab";
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
                  type = "group";
                  name = "Infrastructure";
                  widgets = [
                    {
                      type = "monitor";
                      title = "Glance Dashboard";
                      description = "This dashboard";
                      url = "http://localhost:8080";
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
