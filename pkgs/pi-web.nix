{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
  python3,
}:

buildNpmPackage {
  pname = "pi-web";
  version = "1.202610.1";

  src = fetchFromGitHub {
    owner = "jmfederico";
    repo = "pi-web";
    rev = "787fbf025c97dc99a39cdb1f4e3ff5abf19a8499";
    hash = "sha256-lhJkvQy0gYhqH3ZX3ktuHAufzU8zT9DVI/ml8rE2vTk=";
  };
  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-fZvBvQv7EPAu/ZemRBWyWb0AYflgAHAPYW1A3uQsGR4=";
  makeCacheWritable = true;
  # Seven nested Pi 1.0.0 entries in the upstream lock omit integrity. Supply
  # the registry-published checksums without changing any dependency versions.
  postPatch = ''
    ${python3}/bin/python3 - <<'PY'
    import json
    from pathlib import Path
    path = Path("package-lock.json")
    lock = json.loads(path.read_text())
    integrities = json.loads(Path("${./pi-web-integrities.json}").read_text())
    for name, entry in lock["packages"].items():
        if name and "integrity" not in entry:
            assert entry["version"] == "1.0.0", (name, entry)
            entry["integrity"] = integrities[name.rsplit("node_modules/", 1)[1]]
    path.write_text(json.dumps(lock, indent=2) + "\n")
    PY
  '';
  nodejs = nodejs_24;
  nativeBuildInputs = [ python3 ];

  # Do not run arbitrary dependency lifecycle scripts. Build the one native
  # runtime dependency explicitly against Nix's Node headers, without downloads.
  npmFlags = [ "--ignore-scripts" ];
  preBuild = ''
    npm rebuild node-pty --ignore-scripts=false --offline --nodedir=${nodejs_24}
  '';

  # The upstream lock places the required Pi SDK peers in devDependencies.
  # Keep that pinned SDK graph rather than letting npm prune the runtime away.
  dontNpmPrune = true;
  npmPackFlags = [ "--ignore-scripts" ];

  meta = {
    description = "Web UI and daemon for persistent Pi Coding Agent sessions";
    homepage = "https://pi-web.dev";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "pi-web";
  };
}
