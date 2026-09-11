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
  };
}
