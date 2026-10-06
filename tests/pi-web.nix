# Run: nix eval --offline --impure --json --file tests/pi-web.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
in
builtins.mapAttrs (host: system:
  let
    c = system.config;
    web = c.services.pi-web;
    daemon = c.systemd.services.pi-web-sessiond;
    isGateway = host == "frodo";
  in
  assert web.enable && web.gateway.enable == isGateway;
  assert web.user == (if isGateway then "pi-web" else "gustl");
  assert daemon.serviceConfig.User == web.user;
  assert daemon.serviceConfig.NoNewPrivileges;
  assert !daemon.restartIfChanged && !daemon.stopIfChanged;
  assert c.systemd.services.pi-web.environment.PI_WEB_HOST == "127.0.0.1";
  assert lib.all (port: !(builtins.elem port c.networking.firewall.allowedTCPPorts)) [ 8504 8506 8511 8512 ];
  assert web.manageAgentSettings == isGateway;
  assert (if isGateway then (
    web.isolate && daemon.serviceConfig.ProtectHome
    && builtins.elem "/data/pi-web" daemon.unitConfig.RequiresMountsFor
    && lib.hasInfix "/bin/mountpoint -q /data" c.systemd.services.pi-web-state.preStart
    && lib.hasInfix "/bin/chown root:root /data" c.systemd.services.pi-web-state.preStart
    && c.systemd.services.pi-web-auth.unitConfig.ConditionPathExists == web.gateway.passwordHashFile
    && c.systemd.services.pi-web-auth.serviceConfig.DynamicUser
    && lib.hasInfix "admin unix//run/caddy/admin.sock" c.services.caddy.globalConfig
    && lib.hasInfix "MaxSessions 0" c.services.openssh.extraConfig
    && lib.hasInfix "PermitListen 127.0.0.1:8511" c.services.openssh.extraConfig
    && lib.hasInfix "PermitListen 127.0.0.1:8512" c.services.openssh.extraConfig
    && lib.hasInfix "AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u" c.services.openssh.extraConfig
    && map builtins.readFile c.users.users.pi-web-desktop.openssh.authorizedKeys.keyFiles == [ (builtins.readFile ../ssh/desktop.pub) ]
    && map builtins.readFile c.users.users.pi-web-laptop.openssh.authorizedKeys.keyFiles == [ (builtins.readFile ../ssh/laptop.pub) ]
    && !(builtins.hasAttr "hermes-agent" c.systemd.services)
    && !(builtins.hasAttr "hermes" c.users.users)
    && !(builtins.hasAttr "hermes_env" c.sops.secrets)
    && lib.all (p: !(lib.hasInfix "hermes" (p.pname or p.name or ""))) c.environment.systemPackages
    && !(builtins.elem "wheel" c.users.users.pi-web.extraGroups)
    && !(builtins.elem "docker" c.users.users.pi-web.extraGroups)
  ) else (
    !web.isolate && web.agentDir == "/home/gustl/.pi/agent"
    && web.tunnel.enable
    && lib.hasInfix "StrictHostKeyChecking=yes" c.systemd.services.pi-web-tunnel.serviceConfig.ExecStart
    && lib.hasInfix "-R 127.0.0.1:" c.systemd.services.pi-web-tunnel.serviceConfig.ExecStart
    && c.systemd.services.pi-web-tunnel.unitConfig.ConditionPathExists == web.tunnel.identityFile
    && web.tunnel.identityFile == "/run/secrets/${c.sops.secrets.ssh_user_ed25519_key.name}"
    && c.systemd.services.pi-web-tunnel.serviceConfig.ProtectHome
    && builtins.elem "pi-web-tunnel.service" c.sops.secrets.ssh_user_ed25519_key.restartUnits
  ));
  { passed = true; user = web.user; version = web.package.version; }
) flake.nixosConfigurations
