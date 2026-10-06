# Native runtime, authentication, WebSockets, and authenticated fleet links.
# Run: nix build --impure --no-link --file tests/pi-web-vm.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  piWeb = pkgs.callPackage ../pkgs/pi-web.nix { };
  modules = piWeb + "/lib/node_modules/@jmfederico/pi-web/node_modules";
  # Disposable VM-only identities, never production credentials. Public files
  # are declared by Nix; the client private fixture simulates a SOPS secret.
  testKeys = pkgs.runCommand "pi-web-vm-ssh-fixtures" { } ''
    mkdir -p "$out"
    ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C pi-web-vm-client -f "$out/client"
    ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" -C pi-web-vm-host -f "$out/host"
  '';
  wsTest = pkgs.writeText "pi-web-ws-test.mjs" ''
    import WebSocket from '${modules}/ws/wrapper.mjs';
    const anonymous = process.argv[3] === 'anonymous';
    const socket = new WebSocket(process.argv[2], {
      rejectUnauthorized: false,
      headers: anonymous ? {} : { Authorization: 'Basic ' + Buffer.from('gustl:integration-test-password').toString('base64') },
      origin: 'https://pi.frodo.local',
    });
    const timeout = setTimeout(() => { socket.terminate(); process.exit(1); }, 10000);
    socket.on('open', () => {
      clearTimeout(timeout);
      if (anonymous) process.exit(1);
      socket.close();
    });
    socket.on('unexpected-response', (_, response) => {
      clearTimeout(timeout);
      process.exit(anonymous && response.statusCode === 401 ? 0 : 1);
    });
    socket.on('error', error => { console.error(error); process.exit(1); });
  '';
  ptyTest = pkgs.writeText "pi-web-pty-test.cjs" ''
    const pty = require('${modules}/node-pty');
    const terminal = pty.spawn('/bin/sh', ['-c', 'printf native-pty-ok'], {env: process.env});
    let output = "";
    const timeout = setTimeout(() => process.exit(1), 10000);
    terminal.onData(data => { output += data; });
    terminal.onExit(({exitCode}) => { clearTimeout(timeout); process.exit(exitCode === 0 && output.includes('native-pty-ok') ? 0 : 1); });
  '';
in
pkgs.testers.runNixOSTest {
  name = "pi-web-private-fleet";
  nodes = {
    gateway = { ... }: {
      imports = [ ../modules/services/pi-web.nix ../modules/services/pi-web-frodo-storage.nix ];
      virtualisation.memorySize = 1536;
      virtualisation.fileSystems."/data" = { device = "tmpfs"; fsType = "tmpfs"; options = [ "mode=0775" ]; };
      # Reproduce Frodo's actual legacy ownership, not an idealized root:root
      # mount. The production storage hook must fix only the mounted root.
      systemd.services.legacy-data-layout = {
        before = [ "pi-web-state.service" ];
        requiredBy = [ "pi-web-state.service" ];
        unitConfig.RequiresMountsFor = [ "/data" ];
        serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
        script = ''
          mkdir -p /data/unrelated
          touch /data/unrelated/keep
          chown 987:302 /data /data/unrelated /data/unrelated/keep
          chmod 0775 /data
          chmod 2770 /data/unrelated
          chmod 0640 /data/unrelated/keep
        '';
      };
      services.pi-web = {
        enable = true;
        package = piWeb;
        environment.PI_WEB_OFFLINE = "1";
        gateway = {
          enable = true;
          allowedNetworks = [ "127.0.0.1" "::1" ];
          machines = { desktop = 8511; };
        };
      };
      services.caddy.enable = true;
      networking.hosts."127.0.0.1" = [ "pi.frodo.local" ];
      services.openssh = {
        enable = true;
        hostKeys = [ { type = "ed25519"; path = "/etc/ssh/ssh_host_ed25519_key"; } ];
        settings = { PasswordAuthentication = false; PermitRootLogin = "no"; };
      };
      environment.etc."ssh/ssh_host_ed25519_key" = {
        source = "${testKeys}/host";
        mode = "0600";
      };
      users.users.pi-web-desktop.openssh.authorizedKeys.keyFiles = [ "${testKeys}/client.pub" ];
      environment.systemPackages = [ pkgs.caddy pkgs.curl pkgs.jq pkgs.nodejs_24 ];
    };
    workstation = { ... }: {
      imports = [ ../modules/services/pi-web.nix ];
      virtualisation.memorySize = 1536;
      users.users.gustl = { isNormalUser = true; };
      system.activationScripts.vmTunnelSecret = {
        deps = [ "users" "groups" ];
        text = ''
          mkdir -p /run/secrets
          chmod 0751 /run/secrets
          ${pkgs.coreutils}/bin/install -m 0600 -o gustl -g users ${testKeys}/client /run/secrets/ssh_user_ed25519_key
        '';
      };
      services.pi-web = {
        enable = true;
        package = piWeb;
        user = "gustl";
        group = "users";
        home = "/home/gustl";
        stateDir = "/var/lib/pi-web-gustl";
        manageAgentSettings = true;
        environment.PI_WEB_OFFLINE = "1";
        tunnel = {
          enable = true;
          server = "gateway";
          serverPublicKey = pkgs.lib.fileContents "${testKeys}/host.pub";
          identityFile = "/run/secrets/ssh_user_ed25519_key";
          account = "pi-web-desktop";
          remotePort = 8511;
        };
      };
      environment.systemPackages = [ pkgs.curl pkgs.nodejs_24 ];
    };
  };
  testScript = ''
    import json

    start_all()
    for node in (gateway, workstation):
        node.wait_for_unit("pi-web.service")
        node.wait_for_open_port(8504)
        node.wait_until_succeeds("curl --fail -s http://127.0.0.1:8504/api/sessiond/health")
        node.succeed("ss -ltn | grep '127.0.0.1:8504'")
    gateway.wait_for_unit("data.mount")
    gateway.wait_for_unit("caddy.service")

    with subtest("legacy storage ownership repaired without changing child data"):
        assert gateway.succeed("stat -c '%u:%g:%a' /data").strip() == "0:0:755"
        assert gateway.succeed("stat -c '%u:%g:%a' /data/unrelated").strip() == "987:302:2770"
        assert gateway.succeed("stat -c '%u:%g:%a' /data/unrelated/keep").strip() == "987:302:640"

    with subtest("missing browser credential fails closed"):
        gateway.fail("curl --fail -ks --resolve pi.frodo.local:443:127.0.0.1 https://pi.frodo.local/")
        gateway.fail("ss -ltn | grep ':8506 '")
        gateway.succeed("test $(stat -c %a /data/pi-web) = 700")
        gateway.fail("su pi-web-desktop -c 'cat /data/pi-web/config.json'")

    with subtest("password protects pages, API, and WebSockets"):
        gateway.succeed("printf '%s\\n' integration-test-password | caddy hash-password --bcrypt-cost 4 > /var/lib/pi-web-gateway/password.hash")
        gateway.succeed("chmod 600 /var/lib/pi-web-gateway/password.hash; systemctl start pi-web-auth.service")
        gateway.wait_for_open_port(8506)
        url = "https://pi.frodo.local"
        curl = "curl -ks --resolve pi.frodo.local:443:127.0.0.1"
        assert gateway.succeed(curl + " -o /dev/null -w '%{http_code}' " + url).strip() == "401"
        assert gateway.succeed(curl + " -o /dev/null -w '%{http_code}' " + url + "/api/projects").strip() == "401"
        auth = " -u gustl:integration-test-password"
        gateway.succeed(curl + auth + " --fail " + url)
        gateway.succeed(curl + auth + " --fail " + url + "/api/pi-web/health")
        assert gateway.succeed(curl + auth + " -H 'Origin: https://evil.example' -o /dev/null -w '%{http_code}' " + url).strip() == "403"
        assert gateway.succeed(curl + auth + " --interface 127.0.0.2 -o /dev/null -w '%{http_code}' " + url).strip() == "403"
        # The test browser sends the gateway's canonical Host and Origin.
        gateway.succeed("node ${wsTest} wss://pi.frodo.local/api/events anonymous")
        gateway.succeed("node ${wsTest} wss://pi.frodo.local/api/events")
        gateway.succeed("systemctl reload caddy.service")
        gateway.fail("curl --fail -s http://127.0.0.1:2019/config/")
        gateway.fail("su pi-web-desktop -c 'curl --unix-socket /run/caddy/admin.sock http://localhost/config/'")

    with subtest("native terminal addon works as the workstation user"):
        workstation.succeed("su gustl -c 'node ${ptyTest}'")
        assert workstation.succeed("systemctl show pi-web-sessiond -p User --value").strip() == "gustl"
        assert gateway.succeed("systemctl show pi-web-sessiond -p User --value").strip() == "pi-web"
        runtime = json.loads(gateway.succeed("curl --fail -s http://127.0.0.1:8504/api/pi-web/runtime"))
        assert runtime["components"]["sessiond"]["available"], runtime
        manifest = json.loads(gateway.succeed("curl --fail -s http://127.0.0.1:8504/pi-web-plugins/manifest.json"))
        assert manifest, manifest

    with subtest("fleet connects at boot with declarative keys, no manual enrollment"):
        workstation.wait_for_unit("pi-web-tunnel.service")
        gateway.wait_for_open_port(8511)
        workstation.succeed("test ! -e /var/lib/pi-web-gustl/tunnel_ed25519")
        assert workstation.succeed("stat -c '%U:%a' /run/secrets/ssh_user_ed25519_key").strip() == "gustl:600"
        assert workstation.succeed("systemctl show pi-web-tunnel -p ProtectHome --value").strip() == "yes"
        gateway.succeed("test -r /etc/ssh/authorized_keys.d/pi-web-desktop; test ! -e /var/lib/pi-web-links/desktop.pub")
        gateway.succeed("ss -ltn | grep '127.0.0.1:8511'")
        gateway.succeed("curl --fail -s http://127.0.0.1:8511/api/pi-web/health")
        machines = json.loads(gateway.succeed("curl --fail -s http://127.0.0.1:8504/api/machines"))["machines"]
        assert {m["id"] for m in machines} == {"local", "desktop"}, machines
        gateway.succeed("curl --fail -s http://127.0.0.1:8504/api/machines/desktop/projects")
        ssh = "su gustl -c 'ssh -F /dev/null -i /run/secrets/ssh_user_ed25519_key -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${pkgs.writeText "pi-web-test-known-hosts" "gateway ${pkgs.lib.fileContents "${testKeys}/host.pub"}\n"} "
        workstation.fail(ssh + "pi-web-desktop@gateway id'")
        workstation.fail(ssh + "-N -o ExitOnForwardFailure=yes -R 127.0.0.1:8599:127.0.0.1:8504 pi-web-desktop@gateway'")
        gateway.fail("ss -ltn | grep ':8599 '")

    with subtest("root directory setup never follows agent-controlled child symlinks"):
        workstation.succeed("systemctl stop pi-web.service pi-web-sessiond.service")
        before = workstation.succeed("stat -c '%u:%g:%a' /etc").strip()
        workstation.succeed("su gustl -c 'mv /var/lib/pi-web-gustl/workspace /var/lib/pi-web-gustl/workspace-old; ln -s /etc /var/lib/pi-web-gustl/workspace'")
        workstation.succeed("systemctl restart pi-web-state.service")
        assert workstation.succeed("stat -c '%u:%g:%a' /etc").strip() == before
        workstation.succeed("su gustl -c 'rm /var/lib/pi-web-gustl/workspace; mv /var/lib/pi-web-gustl/workspace-old /var/lib/pi-web-gustl/workspace'")
        workstation.succeed("systemctl start pi-web-sessiond.service pi-web.service")
        workstation.wait_for_open_port(8504)

    with subtest("web restart retains daemon ownership and registry"):
        before = gateway.succeed("systemctl show pi-web-sessiond -p MainPID --value").strip()
        gateway.succeed("systemctl restart pi-web.service")
        gateway.wait_for_open_port(8504)
        after = gateway.succeed("systemctl show pi-web-sessiond -p MainPID --value").strip()
        assert before == after
        assert gateway.succeed("stat -c %a /data/pi-web/data/machines.json").strip() == "600"
  '';
}
