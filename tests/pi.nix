# Run: nix build --impure --no-link --file tests/pi.nix
let
  flake = builtins.getFlake (toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  activation = flake.nixosConfigurations.laptop.config.home-manager.users.gustl.home.activation.configurePi.data;
in
pkgs.runCommand "pi-settings-check" { nativeBuildInputs = [ pkgs.jq ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  run() { "$@"; }
  activate() {
    ${activation}
  }

  # First activation creates writable settings with all three store packages.
  activate
  settings="$HOME/.pi/agent/settings.json"
  test -w "$settings"
  test ! -L "$settings"
  jq -e '.theme == "dark" and .defaultProvider == "openai-codex"
    and .defaultModel == "gpt-6-astra" and (.packages | length == 3)' "$settings"
  while IFS= read -r package; do
    test -f "$package/package.json"
  done < <(jq -r '.packages[]' "$settings")

  # Re-activation restores managed keys but preserves mutable state and auth.
  jq '.theme = "light" | .quietStartup = true | .lastChangelogVersion = "test"' \
    "$settings" > "$settings.new"
  mv "$settings.new" "$settings"
  printf 'local-only' > "$HOME/.pi/agent/auth.json"
  activate
  jq -e '.theme == "dark" and .quietStartup == true
    and .lastChangelogVersion == "test"' "$settings"
  test "$(cat "$HOME/.pi/agent/auth.json")" = local-only
  cp "$settings" "$TMPDIR/expected.json"
  activate
  cmp "$settings" "$TMPDIR/expected.json"

  # Invalid existing data must not be overwritten, nor leave temporary files.
  printf 'invalid JSON' > "$settings"
  if (set -e; activate); then
    echo "Activation unexpectedly accepted invalid JSON" >&2
    exit 1
  fi
  test "$(cat "$settings")" = 'invalid JSON'
  test "$(find "$HOME/.pi/agent" -name 'settings.json.*' | wc -l)" -eq 0
  touch "$out"
''
