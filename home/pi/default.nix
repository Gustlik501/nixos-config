{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  plugins = import ../../pkgs/pi-plugins { inherit pkgs; };
  settings = pkgs.writeText "pi-settings.json" (builtins.toJSON {
    theme = "dark";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-6-astra";
    packages = map (name: "${plugins}/node_modules/${name}") [
      "@tian.zuo/pi-usage"
      "pi-web-access"
      "@calesennett/pi-codex-fast"
    ];
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

  # Do not symlink settings.json into the read-only store: Pi writes to it for
  # /settings, model selection and changelog state. Auth and sessions stay local.
  home.activation.configurePi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe configure}
  '';
}
