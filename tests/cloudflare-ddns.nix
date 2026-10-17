# Offline mocked API tests of the actual Bash script; supplies all dependencies.
# Run: nix build --offline --impure --no-link --file tests/cloudflare-ddns.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  config = flake.nixosConfigurations.frodo.config;
in
assert config.systemd.services.cloudflare-ddns.serviceConfig.EnvironmentFile == config.sops.templates."cloudflare-ddns.env".path;
assert config.services.frodo-vpn.endpointFile == config.sops.secrets.wireguard_endpoint.path;
assert config.sops.templates."cloudflare-ddns.env".mode == "0400";
assert !config.services.cloudflare-ddns.enable;
assert config.sops.secrets.cloudflare_ddns_token.mode == "0400";
assert config.systemd.services.cloudflare-ddns.serviceConfig.DynamicUser;
assert config.systemd.services.cloudflare-ddns.serviceConfig.LoadCredential == [ "token:${config.sops.secrets.cloudflare_ddns_token.path}" ];
assert config.systemd.services.cloudflare-ddns.unitConfig.ConditionFileNotEmpty == config.sops.secrets.cloudflare_ddns_token.path;
assert config.systemd.timers.cloudflare-ddns.timerConfig.OnUnitInactiveSec == "5min";
pkgs.runCommand "cloudflare-ddns-offline-tests" { } ''
  export PATH=${pkgs.lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.python3 pkgs.coreutils ]}:$PATH
  ${pkgs.python3}/bin/python3 -B ${../.}/tests/test_cloudflare_ddns.py -v
  touch "$out"
''
