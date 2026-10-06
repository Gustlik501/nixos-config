{ config, lib, pkgs, ... }:
let
  cfg = config.services.pi-web;
  inherit (lib) mkEnableOption mkIf mkOption types;
  defaults = pkgs.writeText "pi-web-default-config.json" (builtins.toJSON {
    plugins.updates.enabled = false;
  });
  agentSettings = pkgs.writeText "pi-web-agent-settings.json" (builtins.toJSON cfg.agentSettings);
  machines = pkgs.writeText "pi-web-machines.json" (builtins.toJSON {
    machines = lib.mapAttrsToList (name: port: {
      id = name;
      inherit name;
      kind = "remote";
      baseUrl = "http://127.0.0.1:${toString port}";
      createdAt = "2026-10-05T00:00:00.000Z";
      updatedAt = "2026-10-05T00:00:00.000Z";
    }) cfg.gateway.machines;
  });
  seedMachines = pkgs.writeText "pi-web-seed-machines.py" ''
    import json
    import os
    import sys
    from pathlib import Path

    path = Path(sys.argv[1])
    desired = json.loads(Path(sys.argv[2]).read_text())["machines"]
    current = json.loads(path.read_text()) if path.exists() else {"machines": []}
    owned_ids = {machine["id"] for machine in desired}
    current["machines"] = [m for m in current["machines"] if m["id"] not in owned_ids] + desired
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(current, indent=2) + "\n")
    tmp.chmod(0o600)
    os.replace(tmp, path)
  '';
  environment = {
    HOME = cfg.home;
    PI_WEB_HOST = "127.0.0.1";
    PI_WEB_PORT = toString cfg.port;
    PI_WEB_DATA_DIR = "${cfg.stateDir}/data";
    PI_WEB_CONFIG = "${cfg.stateDir}/config.json";
    PI_WEB_SESSIOND_SOCKET = "${cfg.stateDir}/data/sessiond.sock";
    PI_CODING_AGENT_DIR = cfg.agentDir;
    PI_WEB_SKIP_VERSION_CHECK = "1";
  } // cfg.environment;
  common = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "pi-web-directories.service" ];
    requires = [ "pi-web-directories.service" ];
    unitConfig.RequiresMountsFor = [ cfg.stateDir cfg.home ];
    inherit environment;
    path = (with pkgs; [ bashInteractive coreutils curl fd git jq nodejs_24 openssh python3 ripgrep ])
      ++ cfg.extraPackages ++ [ cfg.package ];
    serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = cfg.workspace;
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      # Agent work is deliberately not a sandbox on the workstations. On
      # Frodo, restrict writes to the dedicated user's own state/workspaces.
      ProtectSystem = if cfg.isolate then "strict" else "full";
      ProtectHome = cfg.isolate;
      ReadWritePaths = lib.optional cfg.isolate cfg.stateDir;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };
  };
  authConfig = pkgs.writeText "pi-web-auth.Caddyfile" ''
    {
      admin off
      auto_https off
    }
    http://:${toString cfg.gateway.authPort} {
      bind 127.0.0.1
      route {
        @foreignOrigin {
          header Origin *
          not header Origin https://${cfg.gateway.hostName}
        }
        respond @foreignOrigin "Origin not allowed" 403
        basic_auth {
          gustl {$PI_WEB_PASSWORD_HASH}
        }
        reverse_proxy 127.0.0.1:${toString cfg.port} {
          header_up -Authorization
        }
      }
    }
  '';
  authStart = pkgs.writeShellScript "pi-web-auth-start" ''
    set -eu
    PI_WEB_PASSWORD_HASH=$(${pkgs.coreutils}/bin/tr -d '\n' < "$CREDENTIALS_DIRECTORY/password-hash")
    export PI_WEB_PASSWORD_HASH
    # Reject empty or malformed provisioning before starting any listener.
    [[ "$PI_WEB_PASSWORD_HASH" =~ ^\$2[aby]\$[0-9][0-9]\$[./A-Za-z0-9]{53}$ ]] || exit 1
    exec ${pkgs.caddy}/bin/caddy run --config ${authConfig} --adapter caddyfile
  '';
  setPassword = pkgs.writeShellApplication {
    name = "pi-web-password";
    runtimeInputs = [ pkgs.caddy pkgs.coreutils ];
    text = ''
      if [ "$EUID" -ne 0 ]; then
        echo "Run sudo pi-web-password on Frodo." >&2
        exit 1
      fi
      if [ ! -t 0 ]; then
        echo "Use an interactive terminal; passwords are never command-line arguments." >&2
        exit 1
      fi
      read -r -s -p 'New pi-web browser password: ' password
      printf '\n'
      read -r -s -p 'Repeat password: ' confirmation
      printf '\n'
      if [ "$password" != "$confirmation" ] || [ "''${#password}" -lt 16 ]; then
        echo "Passwords must match and be at least 16 characters." >&2
        exit 1
      fi
      umask 077
      mkdir -p ${lib.escapeShellArg (builtins.dirOf cfg.gateway.passwordHashFile)}
      tmp=$(mktemp ${lib.escapeShellArg "${cfg.gateway.passwordHashFile}.XXXXXX"})
      trap 'rm -f "$tmp"' EXIT
      printf '%s\n' "$password" | caddy hash-password > "$tmp"
      unset password confirmation
      mv -f "$tmp" ${lib.escapeShellArg cfg.gateway.passwordHashFile}
      echo 'Password saved. Username: gustl. No services restarted.'
      echo 'Apply with: sudo systemctl restart pi-web-auth.service'
    '';
  };
in
{
  options.services.pi-web = {
    enable = mkEnableOption "private Pi Web sessions";
    package = mkOption { type = types.package; default = pkgs.callPackage ../../pkgs/pi-web.nix { }; };
    user = mkOption { type = types.str; default = "pi-web"; };
    group = mkOption { type = types.str; default = "pi-web"; };
    home = mkOption { type = types.str; default = cfg.stateDir; };
    stateDir = mkOption { type = types.str; default = "/data/pi-web"; };
    workspace = mkOption { type = types.str; default = "${cfg.stateDir}/workspace"; };
    agentDir = mkOption { type = types.str; default = "${cfg.home}/.pi/agent"; };
    manageAgentSettings = mkOption { type = types.bool; default = cfg.user == "pi-web"; };
    agentSettings = mkOption {
      type = types.attrs;
      default = let plugins = pkgs.callPackage ../../pkgs/pi-plugins { }; in {
        theme = "dark";
        defaultProvider = "openai-codex";
        defaultModel = "gpt-6-astra";
        packages = map (name: "${plugins}/node_modules/${name}") [
          "@tian.zuo/pi-usage" "pi-web-access" "@calesennett/pi-codex-fast"
        ];
      };
      description = "Nix-owned keys merged on daemon start for a dedicated profile; other settings and credentials are preserved.";
    };
    port = mkOption { type = types.port; default = 8504; };
    isolate = mkOption { type = types.bool; default = cfg.user == "pi-web"; };
    environment = mkOption { type = types.attrsOf types.str; default = { }; };
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
    gateway = {
      enable = mkEnableOption "Frodo's authenticated LAN gateway";
      hostName = mkOption { type = types.str; default = "pi.frodo.local"; };
      allowedNetworks = mkOption {
        type = types.listOf types.str;
        default = [ "127.0.0.0/8" "::1" "192.168.1.0/24" "10.100.0.0/24" ];
      };
      authPort = mkOption { type = types.port; default = 8506; };
      passwordHashFile = mkOption {
        type = types.str;
        default = "/var/lib/pi-web-gateway/password.hash";
        description = "Runtime bcrypt hash, outside the store. May also point to a SOPS secret.";
      };
      machines = mkOption {
        type = types.attrsOf types.port;
        default = { desktop = 8511; laptop = 8512; };
        description = "Managed remote-machine IDs and their loopback SSH-tunnel ports.";
      };
    };
    tunnel = {
      enable = mkEnableOption "workstation-to-Frodo authenticated reverse tunnel";
      server = mkOption { type = types.str; default = "192.168.1.64"; };
      serverPublicKey = mkOption {
        type = types.str;
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKNblSOGpFGOMs8kQdyCuUOh+LGBaS6jFrfKRKoKF2w5";
        description = "Pinned Frodo SSH host key; verify before changing, never use accept-new.";
      };
      knownHostsFile = mkOption {
        type = types.path;
        default = pkgs.writeText "pi-web-frodo-known-hosts" "${cfg.tunnel.server} ${cfg.tunnel.serverPublicKey}\n";
      };
      account = mkOption { type = types.str; default = "pi-web-${config.networking.hostName}"; };
      remotePort = mkOption { type = types.port; default = if config.networking.hostName == "desktop" then 8511 else 8512; };
      identityFile = mkOption { type = types.str; default = "${cfg.stateDir}/tunnel_ed25519"; };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      { assertion = !(cfg.gateway.enable && cfg.tunnel.enable); message = "Pi Web gateway and workstation tunnel roles are mutually exclusive."; }
      { assertion = !cfg.gateway.enable || config.services.caddy.enable; message = "Pi Web gateway needs the existing HTTPS Caddy service."; }
      { assertion = !(builtins.hasAttr "PI_WEB_HOST" cfg.environment); message = "Pi Web must stay bound to loopback."; }
    ];
    users.groups.pi-web = mkIf (cfg.user == "pi-web") { };
    environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.gateway.enable setPassword;

    # Create directories only after the state filesystem is mounted. Never
    # recursively chmod the user's existing Pi profile or projects.
    systemd.services.pi-web-state = {
      description = "Prepare Pi Web persistent directories";
      unitConfig.RequiresMountsFor = [ cfg.stateDir ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "pi-web-state" ''
          set -eu
          # Only provision the top-level path in a root-owned parent. Never
          # chown/chmod descendants that an agent can replace with symlinks.
          ${pkgs.python3}/bin/python3 - <<'PY'
          import stat
          from pathlib import Path
          path = Path("${cfg.stateDir}")
          assert path.is_absolute() and not path.is_symlink(), "Unsafe Pi Web state path"
          for parent in path.parents:
              info = parent.lstat()
              assert stat.S_ISDIR(info.st_mode) and info.st_uid == 0 and not (info.st_mode & 0o022), (
                  "Pi Web state needs root-owned, non-writable parents", str(parent)
              )
          PY
          ${pkgs.coreutils}/bin/install -d -m 0700 -o ${cfg.user} -g ${cfg.group} ${cfg.stateDir}
        '';
      };
    };
    systemd.services.pi-web-directories = {
      description = "Prepare Pi Web directories without elevated permissions";
      after = [ "pi-web-state.service" ];
      requires = [ "pi-web-state.service" ];
      unitConfig.RequiresMountsFor = [ cfg.stateDir ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
        UMask = "0077";
        ExecStart = "${pkgs.coreutils}/bin/mkdir -p ${cfg.workspace} ${cfg.stateDir}/data";
      };
    };
    systemd.services.pi-web-sessiond = common // {
      description = "Pi Web persistent agent sessions";
      # Upgrades must not terminate working agents. Apply the new daemon
      # explicitly once sessions are idle; restart the web server first.
      restartIfChanged = false;
      stopIfChanged = false;
      preStart = ''
        test -e ${cfg.stateDir}/config.json || cp ${defaults} ${cfg.stateDir}/config.json
      '' + lib.optionalString cfg.manageAgentSettings ''
        mkdir -p ${cfg.agentDir}
        current=${cfg.agentDir}/settings.json
        if [ ! -e "$current" ]; then
          current=${pkgs.writeText "pi-web-empty-settings.json" "{}"}
        fi
        tmp=$(mktemp ${cfg.agentDir}/settings.json.XXXXXX)
        trap 'rm -f "$tmp"' EXIT
        jq -s 'if (.[0] | type) != "object" then error("Pi settings must be an object")
          else .[0] * .[1] end' "$current" ${agentSettings} > "$tmp"
        mv -f "$tmp" ${cfg.agentDir}/settings.json
      '';
      serviceConfig = common.serviceConfig // {
        ExecStart = "${cfg.package}/bin/pi-web-sessiond";
      };
    };
    systemd.services.pi-web = common // {
      description = "Pi Web browser/API server";
      after = common.after ++ [ "pi-web-sessiond.service" ];
      wants = [ "pi-web-sessiond.service" ];
      preStart = lib.optionalString cfg.gateway.enable ''
        ${pkgs.python3}/bin/python3 ${seedMachines} ${cfg.stateDir}/data/machines.json ${machines}
      '';
      serviceConfig = common.serviceConfig // { ExecStart = "${cfg.package}/bin/pi-web-server"; };
    };

    services.caddy.virtualHosts = mkIf cfg.gateway.enable {
      ${cfg.gateway.hostName}.extraConfig = ''
        tls internal
        route {
          @outside not remote_ip ${lib.concatStringsSep " " cfg.gateway.allowedNetworks}
          respond @outside "Private network only" 403
          reverse_proxy 127.0.0.1:${toString cfg.gateway.authPort}
        }
      '';
    };
    # Do not leave Caddy's configuration API reachable by every local agent.
    # Its private Unix socket is usable by Caddy/root, not by pi-web/gustl.
    services.caddy.globalConfig = mkIf cfg.gateway.enable "admin unix//run/caddy/admin.sock";
    systemd.services.caddy.serviceConfig = mkIf cfg.gateway.enable {
      RuntimeDirectory = "caddy";
      RuntimeDirectoryMode = "0700";
      ExecReload = lib.mkForce [
        ""
        "${config.services.caddy.package}/bin/caddy reload --config /etc/caddy/caddy_config --adapter caddyfile --address unix//run/caddy/admin.sock --force"
      ];
    };
    systemd.services.pi-web-auth = mkIf cfg.gateway.enable {
      description = "Pi Web browser authentication gate";
      wantedBy = [ "multi-user.target" ];
      after = [ "pi-web.service" ];
      # Missing password means no listener, never an unauthenticated fallback.
      unitConfig.ConditionPathExists = cfg.gateway.passwordHashFile;
      serviceConfig = {
        DynamicUser = true;
        LoadCredential = [ "password-hash:${cfg.gateway.passwordHashFile}" ];
        ExecStart = authStart;
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        UMask = "0077";
        Environment = [ "HOME=/tmp/pi-web-auth" "XDG_CONFIG_HOME=/tmp/pi-web-auth" "XDG_DATA_HOME=/tmp/pi-web-auth" ];
      };
    };

    services.openssh.extraConfig = mkIf cfg.gateway.enable (lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: port: ''
        Match User pi-web-${name}
          AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u
          PasswordAuthentication no
          KbdInteractiveAuthentication no
          AllowTcpForwarding remote
          AllowStreamLocalForwarding no
          PermitListen 127.0.0.1:${toString port}
          PermitOpen none
          GatewayPorts no
          AllowAgentForwarding no
          X11Forwarding no
          PermitTTY no
          MaxSessions 0
        Match all
      '') cfg.gateway.machines
    ));
    users.users = lib.mkMerge [
      (mkIf (cfg.user == "pi-web") {
        pi-web = { isSystemUser = true; group = "pi-web"; home = cfg.home; };
      })
      (mkIf cfg.gateway.enable (lib.mapAttrs' (name: _: lib.nameValuePair "pi-web-${name}" {
        isSystemUser = true;
        group = "pi-web-links";
        # SSH -N is allowed; MaxSessions 0 above rejects shell/SFTP/commands.
        shell = pkgs.bashInteractive;
      }) cfg.gateway.machines))
    ];
    users.groups.pi-web-links = mkIf cfg.gateway.enable { };
    systemd.tmpfiles.rules = lib.optionals cfg.gateway.enable [
      "d /var/lib/pi-web-gateway 0700 root root -"
    ];
    systemd.services.pi-web-tunnel = mkIf cfg.tunnel.enable {
      description = "Private Pi Web link to Frodo";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "pi-web.service" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists = cfg.tunnel.identityFile;
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.openssh}/bin/ssh -N -T -F /dev/null"
          "-o BatchMode=yes -o IdentitiesOnly=yes -o ExitOnForwardFailure=yes"
          "-o StrictHostKeyChecking=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
          "-o GlobalKnownHostsFile=/dev/null -o HostKeyAlgorithms=ssh-ed25519"
          "-o UserKnownHostsFile=${cfg.tunnel.knownHostsFile}"
          "-i ${cfg.tunnel.identityFile}"
          "-R 127.0.0.1:${toString cfg.tunnel.remotePort}:127.0.0.1:${toString cfg.port}"
          "${cfg.tunnel.account}@${cfg.tunnel.server}"
        ];
        Restart = "always";
        RestartSec = "15s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        UMask = "0077";
      };
    };
  };
}
