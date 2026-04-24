{ ... }:

{

  services.adguardhome = {
    enable = true;
    port = 3000;
    settings = {
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://big.oisd.nl/";
          name = "OISD Big";
          id = 2;
        }
      ];

      filtering = {
        rewrites_enabled = true;
        rewrites = [
          {
            domain = "frodo.local";
            answer = "192.168.1.64";
            enabled = true;
          }
          {
            domain = "*.frodo.local";
            answer = "192.168.1.64";
            enabled = true;
          }
        ];
      };
    };
  };
  networking.firewall.allowedTCPPorts = [
    3000
    53
  ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
