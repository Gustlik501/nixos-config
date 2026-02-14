{ ... }:

{

  services.adguardhome = {
    enable = true;
    port = 3000;
    settings = {
      filtering.rewrites = [
        {
          domain = "frodo.lan";
          answer = "192.168.1.64";
        }
        {
          domain = "*.frodo.lan";
          answer = "192.168.1.64";
        }
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    3000
    53
  ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
