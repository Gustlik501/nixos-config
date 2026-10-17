{ config, lib, pkgs, ... }:
let
  cfg = config.services.glance-traffic;
  inventory = pkgs.writeText "glance-traffic-inventory.json" (builtins.toJSON { services = cfg.inventory; });
  sources4 = [ "127.0.0.0/8" "192.168.1.0/24" "10.100.0.0/24" ];
  sources6 = [ "::1/128" "fe80::/10" ];
  logFormat = ''
    output file /var/log/caddy-traffic/access.json {
      mode 0640
      roll_size 10MiB
      roll_keep 6
      roll_keep_for 168h
    }
    format filter {
      wrap json
      fields {
        request>headers delete
        request>uri delete
        request>tls delete
        request>remote_port delete
        resp_headers delete
        user_id delete
      }
    }
  '';
  hosts = lib.concatMap (value: value.hosts) (lib.attrValues cfg.inventory);
  privateDashboard = ''
    @outside_statistics not remote_ip ${lib.concatStringsSep " " (sources4 ++ sources6)}
    respond @outside_statistics "Private dashboard only" 403
  '';
  widget = title: template: {
    type = "custom-api";
    inherit title;
    cache = "30s";
    url = "http://127.0.0.1:8080/assets/traffic/statistics.json";
    template = ''
      {{ $updated := .JSON.String "updated_at" | parseTime "rfc3339" }}
      {{ if or (.JSON.Bool "error") ($updated.Before (offsetNow "-2m")) }}
        <p class="color-negative">Traffic statistics unavailable or stale.</p>
      {{ else }}
        ${template}
      {{ end }}
    '';
  };
in
{
  options.services.glance-traffic = {
    enable = lib.mkEnableOption "private traffic statistics in Glance";
    inventory = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          ports = lib.mkOption { type = lib.types.listOf lib.types.port; default = [ ]; };
          hosts = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
        };
      });
      default = {
        gateway = { name = "HTTPS gateway (all sites)"; ports = [ 80 443 ]; };
        glance = { name = "Glance"; ports = [ 8080 ]; hosts = [ "frodo.local" "glance.frodo.local" ]; };
        jellyfin = { name = "Jellyfin"; ports = [ 8096 8920 ]; hosts = [ "jelly.frodo.local" ]; };
        seerr = { name = "Seerr"; ports = [ 5055 ]; hosts = [ "seerr.frodo.local" ]; };
        vaultwarden = { name = "Vaultwarden"; ports = [ 8222 ]; hosts = [ "vault.frodo.local" ]; };
        pi-web = { name = "Pi Web"; ports = [ 8504 ]; hosts = [ "pi.frodo.local" ]; };
        sonarr = { name = "Sonarr"; ports = [ 8989 ]; hosts = [ "sonarr.frodo.local" ]; };
        radarr = { name = "Radarr"; ports = [ 7878 ]; hosts = [ "radarr.frodo.local" ]; };
        bazarr = { name = "Bazarr"; ports = [ 6767 ]; hosts = [ "bazarr.frodo.local" ]; };
        lidarr = { name = "Lidarr"; ports = [ 8686 ]; hosts = [ "lidarr.frodo.local" ]; };
        prowlarr = { name = "Prowlarr"; ports = [ 9696 ]; hosts = [ "prowlarr.frodo.local" ]; };
        profilarr = { name = "Profilarr"; ports = [ 5678 ]; hosts = [ "profilarr.frodo.local" ]; };
        qbittorrent = { name = "qBittorrent"; ports = [ 8081 ]; hosts = [ "qbit.frodo.local" ]; };
        adguard = { name = "AdGuard (TCP/web UI only)"; ports = [ 53 3000 ]; hosts = [ "adguard.frodo.local" ]; };
        postgresql = { name = "PostgreSQL"; ports = [ 5432 ]; };
        ssh = { name = "SSH"; ports = [ 22 ]; };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [ {
      assertion = config.services.caddy.enable && config.services.glance.enable && config.networking.firewall.backend == "iptables";
      message = "Glance traffic statistics require Caddy, Glance and the iptables private-dashboard guard.";
    } ];
    users.groups.glance-traffic = { };
    systemd.tmpfiles.rules = [ "d /var/log/caddy-traffic 2750 ${config.services.caddy.user} glance-traffic -" ];
    systemd.services.caddy.serviceConfig = {
      SupplementaryGroups = [ "glance-traffic" ];
      ReadWritePaths = [ "/var/log/caddy-traffic" ];
    };
    services.caddy.virtualHosts = lib.mkMerge [
      (lib.genAttrs hosts (_: { inherit logFormat; }))
      {
        "frodo.local".extraConfig = lib.mkBefore privateDashboard;
        "glance.frodo.local".extraConfig = lib.mkBefore privateDashboard;
      }
    ];
    # Narrow privacy guard for this dashboard only; not a reinstatement of the
    # postponed fleet-wide firewall/hardening changes. Intercept before global
    # allowed-port/established rules; retain localhost and the existing LAN/VPN.
    networking.firewall.extraCommands = ''
      iptables -I nixos-fw 1 -p tcp --dport 8080 -j DROP
      ip6tables -I nixos-fw 1 -p tcp --dport 8080 -j DROP
      ${lib.concatMapStringsSep "\n" (source: "iptables -I nixos-fw 1 -s ${source} -p tcp --dport 8080 -j nixos-fw-accept") sources4}
      ${lib.concatMapStringsSep "\n" (source: "ip6tables -I nixos-fw 1 -s ${source} -p tcp --dport 8080 -j nixos-fw-accept") sources6}
    '';
    services.glance.settings.pages = lib.mkAfter [ {
      name = "Statistics";
      columns = [ { size = "full"; widgets = [
        (widget "Requests and connections by service" ''
          <p class="size-h6 margin-bottom-10">Frodo only. Web requests through Caddy, retained logs/last 24h; direct non-loopback TCP connections now. Requests/IPs are not people. Gateway TCP is shared across sites.</p>
          {{ range .JSON.Array "warnings" }}<p class="color-negative size-h6">{{ .String "" }}</p>{{ end }}
          <ul class="list list-gap-10">
          {{ range .JSON.Array "services" }}
            <li><div class="color-highlight">{{ .String "name" }}</div>
              <div class="size-h6">{{ if .Bool "web" }}{{ .Int "requests" }} requests · {{ .Int "unique_ips" }} source IPs · {{ .Int "errors" }} HTTP 4xx/5xx · {{ else }}No web-request metric · {{ end }}{{ .Int "tcp" }} direct TCP now</div>
            </li>
          {{ end }}
          </ul>
        '')
        (widget "Source IPs (not geolocation)" ''
          <ul class="list list-gap-10 collapsible-container" data-collapse-after="15">
          {{ range .JSON.Array "sources" }}
            <li><div class="flex justify-between gap-10"><span class="color-highlight">{{ .String "ip" }}</span><span>{{ .String "network" }}</span></div>
            <div class="size-h6">{{ .String "service" }} · {{ .Int "requests" }} web requests/24h · {{ .Int "tcp" }} TCP now</div></li>
          {{ else }}<li>No external client activity observed.</li>{{ end }}
          </ul>
          <p class="size-h6 margin-top-10">Top 100 service/IP pairs. Socket source only: proxy addresses are not automatically trusted as client identities. Cloudflare edge-only requests are not included.</p>
        '')
        (widget "WireGuard authenticated peers" ''
          <ul class="list list-gap-10">
          {{ range .JSON.Array "vpn" }}
            <li><div class="flex justify-between gap-10"><span class="color-highlight">Peer {{ .String "peer" }}</span><span class="{{ if .Bool "recent" }}color-positive{{ else }}color-primary{{ end }}">{{ if .Bool "recent" }}Recent handshake{{ else }}Idle / not observed{{ end }}</span></div>
            <div class="size-h6">Endpoint: {{ .String "endpoint_ip" }} · received {{ .Int "rx_bytes" }} bytes · sent {{ .Int "tx_bytes" }} bytes</div>
            {{ if ne (.String "handshake_at") "" }}{{ $time := .String "handshake_at" | parseTime "rfc3339" }}<div class="size-h6">Handshake <span {{ $time | toRelativeTime }}></span> ago</div>{{ end }}</li>
          {{ else }}<li>No peer data; check the warning above.</li>{{ end }}
          </ul>
          <p class="size-h6 margin-top-10">Counters since interface/peer reset. Recent means within 3 minutes, not a persistent session or an attack count. No private/preshared keys are read.</p>
        '')
      ]; } ];
    } ];

    systemd.services.glance-status.preStart = "${pkgs.coreutils}/bin/mkdir -p /run/glance-status/traffic";
    systemd.services.glance = {
      wants = [ "glance-traffic.service" ];
      after = [ "glance-traffic.service" ];
      serviceConfig.BindReadOnlyPaths = [ "/run/glance-traffic:/run/glance-status-assets/traffic" ];
    };
    systemd.services.glance-traffic = {
      description = "Sanitized private traffic snapshot for Glance";
      after = [ "glance-wireguard.service" ];
      wants = [ "glance-wireguard.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 ${./glance-traffic.py} ${inventory} ${pkgs.iproute2}/bin/ss /var/log/caddy-traffic /run/glance-wireguard/peers.json /run/glance-traffic/statistics.json";
        DynamicUser = true;
        User = "glance-traffic-collector";
        SupplementaryGroups = [ "glance-traffic" ];
        RuntimeDirectory = "glance-traffic";
        RuntimeDirectoryMode = "0755";
        RuntimeDirectoryPreserve = "yes";
        UMask = "0077";
        TimeoutStartSec = "30s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" ];
      };
    };
    systemd.services.glance-wireguard = {
      description = "Non-secret WireGuard kernel statistics for Glance";
      after = [ "wg-quick-wg0.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 ${./glance-wireguard.py} ${pkgs.wireguard-tools}/bin/wg wg0 /run/glance-wireguard/peers.json";
        User = "root";
        Group = "glance-traffic";
        RuntimeDirectory = "glance-wireguard";
        RuntimeDirectoryMode = "0750";
        RuntimeDirectoryPreserve = "yes";
        UMask = "0077";
        TimeoutStartSec = "12s";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
        RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" ];
      };
    };
    systemd.timers.glance-traffic = {
      wantedBy = [ "timers.target" ];
      timerConfig = { OnBootSec = "10s"; OnUnitActiveSec = "30s"; AccuracySec = "1s"; };
    };
  };
}
