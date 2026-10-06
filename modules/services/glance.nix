{ pkgs, ... }:
let
  statusDirectory = "/run/glance-status";
  statusAssetsDirectory = "/run/glance-status-assets";
  # These stay visible even when stopped or not loaded. All other active/failed
  # system services and active timers are discovered automatically.
  monitoredUnits = pkgs.writeText "glance-monitored-units.json" (builtins.toJSON {
    "adguardhome.service" = "AdGuard Home";
    "bazarr.service" = "Bazarr";
    "caddy.service" = "Caddy (HTTPS proxy)";
    "docker.service" = "Docker daemon";
    "glance.service" = "Glance dashboard";
    "jellyfin.service" = "Jellyfin";
    "lidarr.service" = "Lidarr";
    "pi-web.service" = "Pi Web browser/API";
    "pi-web-sessiond.service" = "Pi Web agent sessions";
    "pi-web-auth.service" = "Pi Web browser login";
    "postgresql.service" = "PostgreSQL";
    "profilarr.service" = "Profilarr (Compose setup)";
    "prowlarr.service" = "Prowlarr";
    "qbittorrent.service" = "qBittorrent";
    "radarr.service" = "Radarr";
    "seerr.service" = "Seerr";
    "sonarr.service" = "Sonarr";
    "sshd.service" = "SSH";
    "vaultwarden.service" = "Vaultwarden";
    "wg-quick-wg0.service" = "WireGuard VPN";
  });
  statusWidget = title: section: {
    type = "custom-api";
    inherit title;
    cache = "30s";
    # Glance serves the sanitized snapshot itself: no new listener, daemon,
    # privileged API, Docker socket access, or database credentials are needed.
    url = "http://127.0.0.1:8080/assets/status.json";
    template = ''
      {{ $updated := .JSON.String "updated_at" | parseTime "rfc3339" }}
      {{ if or (.JSON.Bool "error") ($updated.Before (offsetNow "-2m")) }}
        <p class="color-negative">Service status unavailable or stale. Check glance-status.service and its timer.</p>
      {{ else }}
        <p class="size-h6 margin-bottom-10">Snapshot <span {{ $updated | toRelativeTime }}></span> ago. Systemd state, not an application health check.</p>
        <ul class="list list-gap-10 collapsible-container" data-collapse-after="12">
          {{ range .JSON.Array "${section}" }}
            <li>
              <div class="flex justify-between gap-10">
                <span class="color-highlight">{{ .String "name" }}</span>
                {{ $state := .String "active" }}
                <span class="{{ if eq $state "active" }}color-positive{{ else if or (eq $state "failed") (eq $state "inactive") (eq $state "unknown") }}color-negative{{ else }}color-primary{{ end }}">
                  {{ .String "active" }} / {{ .String "sub" }}
                </span>
              </div>
              <div class="size-h6">{{ .String "unit" }}{{ if ne (.String "load") "loaded" }} ({{ .String "load" }}){{ end }}</div>
            </li>
          {{ else }}
            <li>No units in this section.</li>
          {{ end }}
        </ul>
      {{ end }}
    '';
  };
in
{
  services.glance = {
    enable = true;
    settings = {
      server = {
        port = 8080;
        host = "0.0.0.0";
        assets-path = statusAssetsDirectory;
      };
      pages = [
        {
          name = "Media";
          columns = [
            {
              size = "small";
              widgets = [
                { type = "server-stats"; }
                {
                  type = "monitor";
                  title = "Status";
                  cache = "1m";
                  style = "compact";
                  sites = [
                    {
                      title = "Router";
                      url = "http://192.168.1.254";
                      timeout = "10s";
                    }
                    {
                      title = "Frodo";
                      url = "https://frodo.local";
                      check-url = "http://127.0.0.1:8080";
                    }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "monitor";
                  title = "Services";
                  cache = "1m";
                  sites = [
                    {
                      title = "Pi Web";
                      url = "https://pi.frodo.local";
                      # Checks the local backend, not login or fleet health.
                      check-url = "http://127.0.0.1:8504/api/pi-web/health";
                    }
                    {
                      title = "Seerr";
                      url = "https://seerr.frodo.local";
                      check-url = "http://127.0.0.1:5055";
                    }
                    {
                      title = "Jellyfin";
                      url = "https://jelly.frodo.local";
                      check-url = "http://127.0.0.1:8096";
                    }
                    {
                      title = "Sonarr";
                      url = "https://sonarr.frodo.local";
                      check-url = "http://127.0.0.1:8989";
                    }
                    {
                      title = "Radarr";
                      url = "https://radarr.frodo.local";
                      check-url = "http://127.0.0.1:7878";
                    }
                    {
                      title = "Bazarr";
                      url = "https://bazarr.frodo.local";
                      check-url = "http://127.0.0.1:6767";
                    }
                    {
                      title = "Lidarr";
                      url = "https://lidarr.frodo.local";
                      check-url = "http://127.0.0.1:8686";
                    }
                    {
                      title = "Prowlarr";
                      url = "https://prowlarr.frodo.local";
                      check-url = "http://127.0.0.1:9696";
                    }
                    {
                      title = "Profilarr";
                      url = "https://profilarr.frodo.local";
                      check-url = "http://127.0.0.1:5678";
                    }
                    {
                      title = "qBittorrent";
                      url = "https://qbit.frodo.local";
                      check-url = "http://127.0.0.1:8081";
                    }
                    {
                      title = "VaultWarden";
                      url = "https://vault.frodo.local";
                      check-url = "http://127.0.0.1:8222";
                    }
                    {
                      title = "AdGuard";
                      url = "https://adguard.frodo.local";
                      check-url = "http://127.0.0.1:3000";
                    }
                  ];
                }
                (statusWidget "System services" "services")
                (statusWidget "System infrastructure" "infrastructure")
                (statusWidget "Scheduled maintenance timers" "timers")
              ];
            }
          ];
        }
      ];
    };
  };

  # Ensure the assets directory and initial snapshot exist before Glance starts.
  systemd.services.glance = {
    wants = [ "glance-status.service" ];
    after = [ "glance-status.service" ];
    # DynamicUser + RuntimeDirectoryPreserve puts the collector's directory
    # behind /run/private (0700). File modes alone cannot make it readable by
    # another service. Bind just that directory read-only into Glance's mount
    # namespace, at a path that does not traverse the private parent.
    serviceConfig.BindReadOnlyPaths = [ "${statusDirectory}:${statusAssetsDirectory}" ];
  };

  # Collect status without root privileges or membership in the Docker group.
  # Keep the runtime directory between timer invocations; Glance receives a
  # read-only bind mount of this sanitized JSON directory, not /run/private.
  systemd.services.glance-status = {
    description = "Read-only systemd status snapshot for Glance";
    after = [ "dbus.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${./glance-status.py} ${pkgs.systemd}/bin/systemctl ${monitoredUnits} ${statusDirectory}/status.json";
      DynamicUser = true;
      RuntimeDirectory = "glance-status";
      RuntimeDirectoryMode = "0755";
      RuntimeDirectoryPreserve = "yes";
      UMask = "0022";
      TimeoutStartSec = "15s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = [ "AF_UNIX" ];
      CapabilityBoundingSet = "";
      LockPersonality = true;
    };
  };
  systemd.timers.glance-status = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "30s";
      AccuracySec = "1s";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
