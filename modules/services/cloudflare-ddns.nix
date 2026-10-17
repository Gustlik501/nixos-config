{ config, lib, pkgs, ... }:
let
  cfg = config.services.frodo-ddns;
  updater = pkgs.writeShellApplication {
    name = "cloudflare-ddns";
    runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.jq pkgs.python3 ];
    text = builtins.readFile ./cloudflare-ddns.sh;
  };
in
{
  options.services.frodo-ddns = {
    enable = lib.mkEnableOption "source-safe Cloudflare IPv4 DDNS updates";
    environmentFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        Runtime root-only file setting CF_DDNS_ZONE and CF_DDNS_RECORDS (JSON list of
        existing A records to update; no record creation or proxy changes). Kept out
        of Git and the Nix store; the updater validates both before any API call.
      '';
    };
    tokenFile = lib.mkOption {
      type = lib.types.str;
      description = "Runtime API token file, never a plaintext Nix value/store path.";
    };
    package = lib.mkOption { type = lib.types.package; default = updater; internal = true; };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.cloudflare-ddns = {
      description = "Cloudflare DDNS (allowlisted A records only)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionFileNotEmpty = cfg.tokenFile;
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = cfg.environmentFile;
        ExecStart = lib.getExe cfg.package;
        LoadCredential = [ "token:${cfg.tokenFile}" ];
        DynamicUser = true;
        UMask = "0077";
        TimeoutStartSec = "5min";
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      };
    };
    systemd.timers.cloudflare-ddns = {
      description = "Check home IPv4 every five minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitInactiveSec = "5min";
        RandomizedDelaySec = "30s";
      };
    };
  };
}
