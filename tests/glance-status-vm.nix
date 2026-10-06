# Integration test for the real systemd DynamicUser/mount namespace boundary.
# Run: nix build --impure --no-link --file tests/glance-status-vm.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
in
pkgs.testers.runNixOSTest {
  name = "glance-status-permissions";
  nodes.machine = { lib, ... }: {
    imports = [ ../modules/services/glance.nix ];
    virtualisation.memorySize = 1024;
    users.users.observer.isNormalUser = true;
    # Exercise the actual dashboard templates without external web-app probes.
    services.glance.settings.pages = lib.mkForce [ {
      name = "Test";
      columns = [ {
        size = "full";
        widgets = builtins.filter (w: w.type == "custom-api")
          (builtins.elemAt (builtins.elemAt flake.nixosConfigurations.frodo.config.services.glance.settings.pages 0).columns 1).widgets;
      } ];
    } ];
    environment.systemPackages = [ pkgs.curl ];
  };
  testScript = ''
    import json

    machine.start()
    machine.wait_for_unit("glance.service")
    machine.wait_for_unit("glance-status.timer")
    machine.wait_for_open_port(8080)

    with subtest("private collector output is readable through Glance, not directly"):
        machine.succeed("test -L /run/glance-status")
        machine.fail("su -s /bin/sh observer -c 'test -r /run/glance-status/status.json'")
        data = json.loads(machine.succeed("curl --fail -s http://127.0.0.1:8080/assets/status.json"))
        assert not data["error"]
        assert any(row["unit"] == "pi-web-sessiond.service" for row in data["services"])
        assert not any(row["unit"] == "hermes-agent.service" for row in data["services"])
        machine.succeed("curl --fail --location -s http://127.0.0.1:8080/api/pages/test/content > /tmp/page.html")
        page = machine.succeed("cat /tmp/page.html")
        assert "Pi Web agent sessions" in page, page
        assert "Hermes Agent" not in page, page
        assert "403 Forbidden" not in page, page
        assert "unavailable or stale" not in page, page

    with subtest("bind mount is read-only, including across collector invocations"):
        pid = machine.succeed("systemctl show glance.service -p MainPID --value").strip()
        machine.succeed(f"nsenter -t {pid} -m -- test -r /run/glance-status-assets/status.json")
        machine.fail(f"nsenter -t {pid} -m -- touch /run/glance-status-assets/should-not-write")
        before = data["updated_at"]
        machine.sleep(1)
        machine.succeed("systemctl start glance-status.service")
        after = json.loads(machine.succeed("curl --fail -s http://127.0.0.1:8080/assets/status.json"))
        assert not after["error"]
        assert after["updated_at"] != before

    with subtest("Glance restart retains access"):
        machine.succeed("systemctl restart glance.service")
        machine.wait_for_open_port(8080)
        machine.succeed("curl --fail -s http://127.0.0.1:8080/assets/status.json")
  '';
}
