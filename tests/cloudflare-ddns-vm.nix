# Systemd credential isolation/empty-token handling with an offline fake API.
# Run: nix build --offline --impure --no-link --file tests/cloudflare-ddns-vm.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  token = pkgs.writeText "ddns-disposable-test-token" "dummyTokenForOfflineTestsOnly1234567890";
  fakeCurl = pkgs.writeShellScriptBin "curl" ''
    exec ${pkgs.python3}/bin/python3 ${./test_cloudflare_ddns.py} --fake-curl "$@"
  '';
  updater = pkgs.writeShellScriptBin "cloudflare-ddns-test" ''
    exec ${pkgs.bash}/bin/bash ${../modules/services/cloudflare-ddns.sh}
  '';
  # Production renders this from SOPS; the test only needs placeholder names.
  ddnsEnv = pkgs.writeText "ddns-fixture.env" ''
    CF_DDNS_ZONE=example.com
    CF_DDNS_RECORDS='["example.com","vpn.example.com"]'
  '';
  state = pkgs.writeText "ddns-fixture-state.json" (builtins.toJSON {
    ips = [ "93.184.215.14" "93.184.215.14" ];
    requests = [ ];
    records = {
      "example.com" = [ { id = "11111111111111111111111111111111"; name = "example.com"; type = "A"; content = "8.8.8.8"; proxied = true; ttl = 1; } ];
      "vpn.example.com" = [ { id = "22222222222222222222222222222222"; name = "vpn.example.com"; type = "A"; content = "8.8.8.8"; proxied = false; ttl = 300; } ];
    };
  });
in
pkgs.testers.runNixOSTest {
  name = "cloudflare-ddns-credentials";
  nodes.machine = { ... }: {
    imports = [ ../modules/services/cloudflare-ddns.nix ];
    virtualisation.memorySize = 512;
    users.users.observer.isNormalUser = true;
    services.frodo-ddns = {
      enable = true;
      environmentFile = "${ddnsEnv}";
      tokenFile = "/etc/cloudflare-ddns/token";
      package = updater;
    };
    systemd.services.cloudflare-ddns = {
      path = [ fakeCurl pkgs.coreutils pkgs.jq pkgs.python3 ];
      environment.DDNS_FAKE_STATE = "/var/lib/ddns-fixture/state.json";
      serviceConfig.StateDirectory = "ddns-fixture";
    };
    environment.systemPackages = [ pkgs.python3 ];
    system.activationScripts.ddnsFixtures.text = ''
      mkdir -p /etc/cloudflare-ddns /var/lib/ddns-fixture
      touch /etc/cloudflare-ddns/token
      chmod 0400 /etc/cloudflare-ddns/token
      cp ${state} /var/lib/ddns-fixture/state.json
      chmod 0600 /var/lib/ddns-fixture/state.json
    '';
  };
  testScript = ''
    import json

    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("cloudflare-ddns.timer")

    with subtest("empty placeholder skips before credentials or API calls"):
        machine.succeed("systemctl start cloudflare-ddns.service")
        assert machine.succeed("systemctl show cloudflare-ddns.service -p ConditionResult --value").strip() == "no"
        state = json.loads(machine.succeed("python3 -c \"from pathlib import Path; print(Path('/var/lib/ddns-fixture/state.json').read_text())\""))
        assert state["requests"] == []

    with subtest("root-only secret is passed privately to an unprivileged updater"):
        machine.succeed("install -o root -g root -m 0400 ${token} /etc/cloudflare-ddns/token")
        machine.fail("su -s /bin/sh observer -c 'test -r /etc/cloudflare-ddns/token'")
        machine.succeed("systemctl start cloudflare-ddns.service")
        assert machine.succeed("systemctl show cloudflare-ddns.service -p DynamicUser --value").strip() == "yes"
        assert machine.succeed("systemctl show cloudflare-ddns.service -p Result --value").strip() == "success"
        state = json.loads(machine.succeed("python3 -c \"from pathlib import Path; print(Path('/var/lib/ddns-fixture/state.json').read_text())\""))
        assert all(rows[0]["content"] == "93.184.215.14" for rows in state["records"].values())
        assert state["records"]["example.com"][0]["proxied"] is True
        assert state["records"]["vpn.example.com"][0]["proxied"] is False
        assert len([r for r in state["requests"] if r["method"] == "PATCH"]) == 2
        logs = machine.succeed("journalctl -u cloudflare-ddns.service --no-pager")
        assert "dummyTokenForOfflineTestsOnly1234567890" not in logs

    with subtest("unchanged IP produces no additional writes"):
        machine.succeed("systemctl start cloudflare-ddns.service")
        state = json.loads(machine.succeed("python3 -c \"from pathlib import Path; print(Path('/var/lib/ddns-fixture/state.json').read_text())\""))
        assert len([r for r in state["requests"] if r["method"] == "PATCH"]) == 2
  '';
}
