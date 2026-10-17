# Real Caddy filtering, private dashboard guard, nested asset bind and WG reader.
# Run: nix build --offline --impure --no-link --file tests/glance-traffic-vm.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  backend = pkgs.writeText "traffic-test-backend.py" ''
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Set-Cookie", "SECRET_RESPONSE_CANARY")
            self.end_headers()
            self.wfile.write(b"fixture")
        def log_message(self, *args):
            pass
    ThreadingHTTPServer(("0.0.0.0", 8096), Handler).serve_forever()
  '';
in
pkgs.testers.runNixOSTest {
  name = "glance-private-traffic-statistics";
  nodes = {
    server = { lib, ... }: {
      imports = [ ../modules/services/glance.nix ../modules/services/glance-traffic.nix ];
      virtualisation.memorySize = 1024;
      networking.interfaces.eth1.ipv4.addresses = lib.mkForce [
        { address = "192.168.1.64"; prefixLength = 24; }
        { address = "198.51.100.1"; prefixLength = 24; }
      ];
      networking.firewall.allowedTCPPorts = [ 443 8096 ];
      users.users.observer.isNormalUser = true;
      services.glance-traffic = {
        enable = true;
        inventory = lib.mkForce {
          gateway = { name = "Gateway"; ports = [ 443 ]; hosts = [ ]; };
          glance = { name = "Glance"; ports = [ 8080 ]; hosts = [ "frodo.local" "glance.frodo.local" ]; };
          jelly = { name = "Jellyfin"; ports = [ 8096 ]; hosts = [ "jelly.frodo.local" ]; };
        };
      };
      services.glance.settings.pages = lib.mkForce [ (builtins.elemAt flake.nixosConfigurations.frodo.config.services.glance.settings.pages 1) ];
      services.caddy = {
        enable = true;
        virtualHosts = {
          "frodo.local".extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8080";
          "glance.frodo.local".extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8080";
          "jelly.frodo.local".extraConfig = "tls internal\nreverse_proxy 127.0.0.1:8096";
        };
      };
      systemd.services.fixture-backend = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${backend}";
      };
      environment.systemPackages = [ pkgs.curl pkgs.python3 pkgs.wireguard-tools pkgs.iproute2 ];
      boot.kernelModules = [ "wireguard" ];
    };
    client = { lib, ... }: {
      virtualisation.memorySize = 512;
      networking.interfaces.eth1.ipv4.addresses = lib.mkForce [
        { address = "192.168.1.116"; prefixLength = 24; }
        { address = "198.51.100.2"; prefixLength = 24; }
      ];
      environment.systemPackages = [ pkgs.curl pkgs.python3 ];
    };
  };
  testScript = ''
    import json

    start_all()
    server.wait_for_unit("caddy.service")
    server.wait_for_unit("glance.service")
    server.wait_for_open_port(8080)
    server.wait_for_open_port(8096)
    client.wait_for_unit("multi-user.target")

    with subtest("Caddy logs requests without credentials, cookies or URI tokens"):
        client.succeed("curl -k --fail --silent --noproxy '*' --resolve jelly.frodo.local:443:192.168.1.64 -H 'Authorization: Bearer SECRET_AUTH_CANARY' -H 'Cookie: SECRET_COOKIE_CANARY' 'https://jelly.frodo.local/private/SECRET_URI_CANARY?token=SECRET_QUERY_CANARY' > /dev/null")
        server.wait_until_succeeds("test -s /var/log/caddy-traffic/access.json")
        raw = server.succeed("cat /var/log/caddy-traffic/access.json")
        assert "SECRET_" not in raw, raw
        entry = json.loads(raw.splitlines()[-1])
        assert "headers" not in entry["request"] and "uri" not in entry["request"]
        assert "resp_headers" not in entry
        assert entry["request"]["remote_ip"] == "192.168.1.116"
        server.fail("su -s /bin/sh observer -c 'test -r /var/log/caddy-traffic/access.json'")

    with subtest("live TCP and non-secret WireGuard data reach the statistics asset"):
        server.succeed("ip link add wg0 type wireguard; ip link set wg0 up; umask 077; wg genkey > /tmp/test-wg-key; wg set wg0 private-key /tmp/test-wg-key; wg genkey | wg pubkey > /tmp/test-peer-pub; wg set wg0 peer $(cat /tmp/test-peer-pub) endpoint 198.51.100.9:51820 allowed-ips 10.100.0.2/32")
        client.succeed("python3 -c \"import socket,time; s=socket.create_connection(('192.168.1.64',8096)); time.sleep(90)\" >/dev/null 2>&1 &")
        server.succeed("systemctl start glance-traffic.service")
        data = json.loads(client.succeed("curl --fail --silent http://192.168.1.64:8080/assets/traffic/statistics.json"))
        assert not data["error"], data
        jelly = next(row for row in data["services"] if row["name"] == "Jellyfin")
        assert jelly["requests"] >= 1 and jelly["tcp"] >= 1, jelly
        assert any(row["ip"] == "192.168.1.116" and row["network"] == "LAN" for row in data["sources"])
        assert len(data["vpn"]) == 1 and data["vpn"][0]["endpoint_ip"] == "198.51.100.9", data
        assert "SECRET_" not in json.dumps(data)
        server.fail("su -s /bin/sh observer -c 'test -r /run/glance-wireguard/peers.json'")

    with subtest("Statistics page renders and its mounted asset cannot be written"):
        html = client.succeed("curl --fail --location --silent http://192.168.1.64:8080/api/pages/statistics/content")
        assert "Jellyfin" in html and "Source IPs" in html and "198.51.100.9" in html, html
        assert "403 Forbidden" not in html and "unavailable or stale" not in html, html
        pid = server.succeed("systemctl show glance.service -p MainPID --value").strip()
        server.fail(f"nsenter -t {pid} -m -- touch /run/glance-status-assets/traffic/not-writable")

    with subtest("non-private sources cannot access the dashboard or its raw assets"):
        client.fail("curl --connect-timeout 2 --max-time 3 --silent http://198.51.100.1:8080/assets/traffic/statistics.json")
        code = client.succeed("curl -k --silent --noproxy '*' --resolve frodo.local:443:198.51.100.1 -o /tmp/denied -w '%{http_code}' https://frodo.local/assets/traffic/statistics.json")
        assert code == "403", code

    with subtest("Glance restart retains its read-only statistics view"):
        server.succeed("systemctl restart glance.service")
        server.wait_for_open_port(8080)
        client.succeed("curl --fail --silent http://192.168.1.64:8080/assets/traffic/statistics.json > /dev/null")
  '';
}
