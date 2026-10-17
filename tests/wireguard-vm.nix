# Disposable VM only: no real peer keys, router changes, or external IP services.
# Run: nix build --offline --impure --no-link --file tests/wireguard-vm.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
in
pkgs.testers.runNixOSTest {
  name = "wireguard-dns-client-profile";
  nodes.machine = { lib, ... }: {
    imports = [ ../modules/services/wireguard.nix ../modules/services/adguard.nix ];
    virtualisation.memorySize = 768;
    # The production service uses existing mutable keys. In this VM, initialize
    # disposable keys explicitly before starting it, without a first-boot error.
    systemd.services.wg-quick-wg0.wantedBy = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.python3 ];
    # Trailing newline mirrors a hand-edited secret; the script must strip it.
    services.frodo-vpn.endpointFile = "${pkgs.writeText "vpn-endpoint" "vpn.example.com\n"}";
  };
  testScript = ''
    import json

    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("adguardhome.service")
    machine.wait_for_open_port(53)
    machine.succeed("vpn init > /tmp/vpn-init.log")
    machine.succeed("systemctl start wg-quick-wg0")
    machine.wait_for_unit("wg-quick-wg0.service")
    assert machine.succeed("wg show wg0 listen-port").strip() == "51820"
    machine.succeed("vpn add vm-test-phone > /tmp/vpn-client.log")

    with subtest("new profiles use the DNS endpoint and private DNS, preserving routing"):
        # Read only endpoint/DNS/routing fields out of the VM output; never log
        # private keys or QR codes, even from a disposable fixture.
        fields = json.loads(machine.succeed("python3 -c \"import json,pathlib; lines=pathlib.Path('/tmp/vpn-client.log').read_text().splitlines(); print(json.dumps([line for line in lines if line.startswith(('Endpoint = ', 'DNS = ', 'AllowedIPs = '))]))\""))
        assert "Endpoint = vpn.example.com:51820" in fields, fields
        assert "DNS = 10.100.0.1" in fields, fields
        assert "AllowedIPs = 0.0.0.0/0" in fields, fields
        assert machine.succeed("wg show wg0 peers | wc -l").strip() == "1"
        machine.succeed("test $(stat -c %a /etc/wireguard/wg0.conf) = 600")

    with subtest("private DNS answers the existing LAN names through the VPN address"):
        machine.succeed("python3 - <<'PY'\nimport socket,struct\nname = bytes().join(bytes([len(label)]) + label.encode() for label in 'jelly.frodo.local'.split('.')) + b'\\0'\nquery = struct.pack('!6H', 1234, 0x100, 1, 0, 0, 0) + name + struct.pack('!2H', 1, 1)\ns = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)\ns.settimeout(5)\ns.sendto(query, ('10.100.0.1', 53))\nreply = s.recv(4096)\nheader = struct.unpack('!6H', reply[:12])\nassert header[0] == 1234 and header[1] & 0x8000 and header[1] & 15 == 0 and header[3] >= 1\nassert socket.inet_aton('192.168.1.64') in reply\nPY")
  '';
}
