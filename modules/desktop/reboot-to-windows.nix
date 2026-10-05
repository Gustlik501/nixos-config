{ pkgs, ... }:
let
  # Run through pkexec: no passwordless sudo rule and no caller-selected command.
  helper = pkgs.writeScriptBin "reboot-to-windows-helper" ''
    #!${pkgs.python3}/bin/python3
    import os
    import re
    import subprocess
    import sys

    EFIBOOTMGR = "${pkgs.efibootmgr}/bin/efibootmgr"
    SYSTEMCTL = "${pkgs.systemd}/bin/systemctl"

    def run(*args):
        return subprocess.run(args, check=True, text=True, capture_output=True)

    def main():
        if len(sys.argv) != 1 or os.geteuid() != 0:
            raise RuntimeError("This helper requires administrator authorization and accepts no arguments.")
        if not os.path.isdir("/sys/firmware/efi/efivars"):
            raise RuntimeError("UEFI firmware variables are unavailable.")

        listing = run(EFIBOOTMGR, "--verbose").stdout
        candidates = []
        for line in listing.splitlines():
            match = re.match(r"^Boot([0-9A-Fa-f]{4})\*\s+Windows Boot Manager\s+HD\(", line)
            if match and r"\efi\microsoft\boot\bootmgfw.efi" in line.lower():
                candidates.append(match.group(1))
        if len(candidates) != 1:
            raise RuntimeError("Expected exactly one active Windows Boot Manager firmware entry; found " + str(len(candidates)) + ". No changes made.")
        target = candidates[0]
        previous = re.search(r"^BootNext:\s*([0-9A-Fa-f]{4})", listing, re.MULTILINE)
        try:
            run(EFIBOOTMGR, "--bootnext", target)
            updated = run(EFIBOOTMGR).stdout
            next_entry = re.search(r"^BootNext:\s*([0-9A-Fa-f]{4})", updated, re.MULTILINE)
            if not next_entry or next_entry.group(1).lower() != target.lower():
                raise RuntimeError("Firmware did not retain the requested one-time Windows boot.")
            # No --force: respect shutdown inhibitors and fail rather than bypass them.
            run(SYSTEMCTL, "reboot")
        except Exception:
            try:
                if previous:
                    run(EFIBOOTMGR, "--bootnext", previous.group(1))
                else:
                    run(EFIBOOTMGR, "--delete-bootnext")
            except Exception as rollback_error:
                print("Warning: could not restore BootNext: " + str(rollback_error), file=sys.stderr)
            raise

    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.stderr.strip(), file=sys.stderr)
        sys.exit(1)
  '';

  command = pkgs.writeShellApplication {
    name = "reboot-to-windows";
    text = ''
      if [[ $# -ne 0 ]]; then
        echo "Usage: reboot-to-windows" >&2
        exit 2
      fi
      if [[ -t 0 ]]; then
        printf 'Save your work. Restart directly into Windows now? [y/N] '
        read -r answer || exit 0
        case "$answer" in y|Y|yes|YES) ;; *) exit 0 ;; esac
      else
        ${pkgs.zenity}/bin/zenity --question \
          --title="Reboot into Windows" \
          --text="Save your work first.\n\nRestart directly into Windows for FACEIT?\nYour normal boot order will not change." \
          --ok-label="Restart" --cancel-label="Cancel" --default-cancel || exit 0
      fi

      if output=$(/run/wrappers/bin/pkexec ${helper}/bin/reboot-to-windows-helper 2>&1); then
        exit 0
      else
        status=$?
        # pkexec: authorization dismissed or denied. Never fall back to sudo.
        if [[ $status -eq 126 ]]; then exit 0; fi
        printf '%s\n' "$output" >&2
        if [[ ! -t 0 ]]; then
          ${pkgs.zenity}/bin/zenity --error --no-markup \
            --title="Could not reboot into Windows" --text="$output" || true
        fi
        exit "$status"
      fi
    '';
  };

  launcher = pkgs.makeDesktopItem {
    name = "reboot-to-windows";
    desktopName = "Reboot into Windows";
    comment = "Boot Windows directly for FACEIT (one-time firmware selection)";
    exec = "${command}/bin/reboot-to-windows";
    icon = "system-reboot";
    terminal = false;
    categories = [ "System" ];
    keywords = [ "Windows" "FACEIT" "Restart" "Reboot" ];
  };
in
{
  security.polkit.enable = true;
  environment.systemPackages = [ command launcher ];
}
