{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.vesktop ];

  home.activation.vesktopWalQuickCss = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    vesktop_dir="$HOME/.config/vesktop/settings"
    mkdir -p "$vesktop_dir"

    # Keep Vesktop quick CSS wired directly to cwal output.
    ln -sfn "$HOME/.cache/wal/colors-discord.css" "$vesktop_dir/quickCss.css"

    # Ensure quick CSS is enabled without replacing user settings wholesale.
    vesktop_settings="$vesktop_dir/settings.json"
    if [ -f "$vesktop_settings" ]; then
      sed -i 's/"useQuickCss":[[:space:]]*false/"useQuickCss": true/' "$vesktop_settings" || true
    fi
  '';
}
