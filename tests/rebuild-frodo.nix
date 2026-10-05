# Test the deployment wrappers without SSH, sudo, or activation.
# Run: nix build --impure --no-link --file tests/rebuild-frodo.nix
let
  flake = builtins.getFlake ("path:" + toString ../.);
  pkgs = import flake.inputs.nixpkgs { system = "x86_64-linux"; };
  apps = flake.apps.x86_64-linux;
in
pkgs.runCommand "frodo-deployment-wrapper-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  mkdir -p "$TMPDIR/bin" "$TMPDIR/repo"
  touch "$TMPDIR/repo/flake.nix"
  cat > "$TMPDIR/bin/nixos-rebuild" <<'EOF'
  #!${pkgs.python3}/bin/python3
  import json, os, sys
  with open(os.environ["CAPTURE"], "w") as output:
      json.dump(sys.argv[1:], output)
  EOF
  chmod +x "$TMPDIR/bin/nixos-rebuild"
  export PATH="$TMPDIR/bin:$PATH"
  export CAPTURE="$TMPDIR/args.json"
  cd "$TMPDIR/repo"

  export SWITCH_APP=${apps.rebuild-frodo.program}
  export BOOT_APP=${apps.rebuild-frodo-boot.program}
  python3 - <<'PY'
  import json, os, subprocess
  for app, action in [("SWITCH_APP", "switch"), ("BOOT_APP", "boot")]:
      for override in [None, "operator@alternate-host"]:
          env = dict(os.environ)
          env.pop("FRODO_HOST", None)
          if override:
              env["FRODO_HOST"] = override
          target = override or "gustl@frodo.local"
          subprocess.run([env[app], "--show-trace"], env=env, check=True)
          with open(env["CAPTURE"]) as file:
              args = json.load(file)
          assert args == [
              action, "--flake", os.getcwd() + "#frodo",
              "--build-host", target, "--target-host", target,
              "--sudo", "--ask-sudo-password", "--show-trace",
          ], args
      # A wrong working directory must fail before invoking the rebuild tool.
      os.unlink(os.environ["CAPTURE"])
      result = subprocess.run([os.environ[app]], cwd=os.environ["TMPDIR"], capture_output=True)
      assert result.returncode != 0
      assert not os.path.exists(os.environ["CAPTURE"])
  PY
  touch "$out"
''
