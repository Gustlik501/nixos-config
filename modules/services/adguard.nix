{ ... }:

{

  services.adguardhome = {
    enable = true;
    port = 3000;
    settings = {
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
