# Run: nix build --impure --no-link --file tests/pi.nix
let
  flake = builtins.getFlake (toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  hm = flake.nixosConfigurations.laptop.config.home-manager.users.gustl;
  pi = flake.inputs.llm-agents.packages.x86_64-linux.pi;
  activation = hm.home.activation.configurePi.data;
  keybindings = pkgs.writeText "pi-keybindings.json" hm.home.file.".pi/agent/keybindings.json".text;
in
assert hm.programs.kitty.keybindings."ctrl+v" == "paste_from_clipboard";
pkgs.runCommand "pi-settings-check" { nativeBuildInputs = [ pkgs.jq pkgs.python3 ]; } ''
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

  # Load the actual pinned Pi runtime and all three extensions without user
  # credentials, project resources, network access, or a model request.
  export PI_CODING_AGENT_DIR="$HOME/.pi/agent"
  export PI_OFFLINE=1
  export PI_TEST_BINARY=${pi}/bin/pi
  python3 - <<'PY'
  import json
  import os
  import subprocess

  result = subprocess.run(
      [os.environ["PI_TEST_BINARY"], "--offline", "--mode", "rpc",
       "--no-session", "--no-context-files", "--no-approve"],
      cwd=os.environ["HOME"],
      input='{"id":"state","type":"get_state"}\n'
            '{"id":"commands","type":"get_commands"}\n',
      text=True, capture_output=True, timeout=60, check=True,
  )
  print(result.stderr, end="")
  records = [json.loads(line) for line in result.stdout.splitlines() if line]
  assert not any(r.get("type") == "extension_error" for r in records), records
  responses = {r["id"]: r for r in records if r.get("type") == "response"}
  assert responses["state"]["success"], responses
  assert responses["commands"]["success"], responses
  commands = {c["name"] for c in responses["commands"]["data"]["commands"]}
  assert {"usage", "websearch", "codex-fast"} <= commands, commands
  PY

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
