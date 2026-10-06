{ pkgs }:

# Pi supplies its own peer modules to extensions at runtime. Do not install a
# second copy of the agent (or run third-party lifecycle scripts) in this bundle.
pkgs.importNpmLock.buildNodeModules {
  npmRoot = ./.;
  nodejs = pkgs.nodejs_24;
  derivationArgs = {
    npmFlags = [
      "--legacy-peer-deps"
      "--ignore-scripts"
    ];
    nativeBuildInputs = [ pkgs.jq ];
    postInstall = ''
      # Upstream 0.28.0 declares Pi's host-provided TypeBox as a dependency.
      # Correct the installed manifest and remove that redundant copy; Pi's
      # extension loader supplies the runtime module for both CLI and SDK.
      manifest="$out/node_modules/pi-web-access/package.json"
      jq -e '.name == "pi-web-access" and .version == "0.28.0"
        and .dependencies.typebox == "^1.1.38"' "$manifest" > /dev/null
      jq 'del(.dependencies.typebox) | .peerDependencies.typebox = "*"' \
        "$manifest" > "$manifest.new"
      mv "$manifest.new" "$manifest"
      rm -rf "$out/node_modules/typebox"
    '';
  };
}
