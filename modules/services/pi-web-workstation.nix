{ config, inputs, lib, pkgs, username, ... }:
{
  imports = [ ./pi-web.nix ];
  services.pi-web = {
    enable = true;
    user = username;
    group = "users";
    home = "/home/${username}";
    stateDir = "/var/lib/pi-web-${username}";
    agentDir = "/home/${username}/.pi/agent";
    tunnel = {
      enable = true;
      # The normal ~/.ssh path is hidden by ProtectHome. SOPS also exposes the
      # same 0600, user-owned key at its canonical runtime location.
      identityFile = "/run/secrets/${config.sops.secrets.ssh_user_ed25519_key.name}";
    };
    extraPackages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];
  };
  sops.secrets.ssh_user_ed25519_key.restartUnits = [ "pi-web-tunnel.service" ];
  systemd.services.pi-web-tunnel = lib.mkIf config.sops.useSystemdActivation {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };
  systemd.services.pi-web-sessiond = {
    after = [ "home-manager-${username}.service" ];
    wants = [ "home-manager-${username}.service" ];
  };
}
