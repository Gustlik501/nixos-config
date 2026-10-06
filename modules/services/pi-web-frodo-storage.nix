{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.services.pi-web.enable {
    # The ZFS dataset root is shared infrastructure, not an agent-owned directory.
    # Frodo's legacy /data ownership belongs to a retired UID. Normalize only the
    # mounted root; never recurse into existing applications, data, or workspaces.
    # pi-web-state already requires /data to be mounted before its preStart runs.
    systemd.services.pi-web-state.preStart = ''
      ${pkgs.util-linux}/bin/mountpoint -q /data
      test ! -L /data
      ${pkgs.coreutils}/bin/chown root:root /data
      ${pkgs.coreutils}/bin/chmod 0755 /data
    '';
  };
}
