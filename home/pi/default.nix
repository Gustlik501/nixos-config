{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  plugins = import ../../pkgs/pi-plugins { inherit pkgs; };
  pluginVersions = (lib.importJSON ../../pkgs/pi-plugins/package.json).dependencies;
  pluginNames = [
    "@tian.zuo/pi-usage"
    "pi-web-access"
    "@calesennett/pi-codex-fast"
  ];
  # Declare the plugins as pinned npm packages, linked below to the Nix-built
  # copies. Pi identifies npm packages by name, so a project that lists the
  # same package replaces this one instead of loading it twice (which is a
  # fatal tool conflict). Pinned versions are never updated by Pi.
  settings = pkgs.writeText "pi-settings.json" (builtins.toJSON {
    theme = "dark";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-6-astra";
    packages = map (name: "npm:${name}@${pluginVersions.${name}}") pluginNames;
  });
  configure = pkgs.writeShellApplication {
    name = "configure-pi";
    runtimeInputs = [ pkgs.coreutils pkgs.jq ];
    text = ''
      dir="$HOME/.pi/agent"
      mkdir -p "$dir"
      umask 077
      tmp=$(mktemp "$dir/settings.json.XXXXXX")
      trap 'rm -f "$tmp"' EXIT
      current="$dir/settings.json"
      if [ ! -e "$current" ]; then
        current=${pkgs.writeText "empty-pi-settings.json" "{}"}
      fi
      # Keep Pi's other mutable settings; Nix owns these four keys. Validate
      # before replacing so malformed existing JSON never destroys settings.
      jq -s 'if (.[0] | type) != "object" then error("Pi settings must be an object")
        else .[0] * .[1] end' "$current" ${settings} > "$tmp"
      mv -f "$tmp" "$dir/settings.json"

      # Pi loads user npm packages from its managed npm directory when the
      # installed version matches. Link the whole directory to the Nix bundle
      # so the plugins' own dependencies resolve too.
      modules="$dir/npm/node_modules"
      mkdir -p "$dir/npm"
      if [ -e "$modules" ] && [ ! -L "$modules" ]; then
        rm -rf "$modules"
      fi
      ln -sfn "${plugins}/node_modules" "$modules"
    '';
  };
in
{
  home.packages = [
    llmAgents.pi
    pkgs.nodejs_24
    pkgs.git
    pkgs.ripgrep
    pkgs.fd
    pkgs.xdg-utils
    # Optional video features in pi-web-access need both tools on PATH.
    pkgs.yt-dlp
    pkgs.ffmpeg
  ];

  # Kitty keeps Ctrl+V for terminal text paste. Alt+V reaches Pi directly;
  # retain Ctrl+V as well for terminals that do not intercept it.
  home.file.".pi/agent/keybindings.json".text = builtins.toJSON {
    "app.clipboard.pasteImage" = [ "ctrl+v" "alt+v" ];
  };

  # Do not symlink settings.json into the read-only store: Pi writes to it for
  # /settings, model selection and changelog state. Auth and sessions stay local.
  home.activation.configurePi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe configure}
  '';
}
