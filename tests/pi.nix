# Run: nix build --impure --no-link --file tests/pi.nix
let
  flake = builtins.getFlake (toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  hm = flake.nixosConfigurations.laptop.config.home-manager.users.gustl;
  activation = hm.home.activation.configurePi.data;
  keybindings = pkgs.writeText "pi-keybindings.json" hm.home.file.".pi/agent/keybindings.json".text;
in
assert hm.programs.kitty.keybindings."ctrl+v" == "paste_from_clipboard";
pkgs.runCommand "pi-settings-check" { nativeBuildInputs = [ pkgs.jq ]; } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME/.pi/agent"
  # Home Manager links this declarative file before activation.
  ln -s ${keybindings} "$HOME/.pi/agent/keybindings.json"
  jq -e '."app.clipboard.pasteImage" == ["ctrl+v", "alt+v"]' "$HOME/.pi/agent/keybindings.json"
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
    and .defaultModel == "gpt-6-astra" and (.packages | length == 3)
    and (.packages | map(split("/node_modules/")[1]) ==
      ["@tian.zuo/pi-usage", "pi-web-access", "@calesennett/pi-codex-fast"])' "$settings"
  while IFS= read -r package; do
    test -f "$package/package.json"
  done < <(jq -r '.packages[]' "$settings")

  # Re-activation removes Plannotator but preserves mutable state and auth,
  # including the speed mode saved by pi-codex-fast.
  jq '.theme = "light" | .quietStartup = true | .lastChangelogVersion = "test"
    | .packages = ["/old/node_modules/@plannotator/pi-extension"]
    | ."pi-codex-fast" = {mode: "fast", enabled: true}' \
    "$settings" > "$settings.new"
  mv "$settings.new" "$settings"
  printf 'local-only' > "$HOME/.pi/agent/auth.json"
  activate
  jq -e '.theme == "dark" and .quietStartup == true
    and .lastChangelogVersion == "test"
    and ."pi-codex-fast" == {mode: "fast", enabled: true}
    and (.packages | map(split("/node_modules/")[1]) ==
      ["@tian.zuo/pi-usage", "pi-web-access", "@calesennett/pi-codex-fast"])' "$settings"
  test "$(cat "$HOME/.pi/agent/auth.json")" = local-only
  cp "$settings" "$TMPDIR/expected.json"
  activate
  cmp "$settings" "$TMPDIR/expected.json"
  cmp "$HOME/.pi/agent/keybindings.json" ${keybindings}

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
