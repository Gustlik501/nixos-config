{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.cwal ];

  # cwal theme listing appears to ignore symlink entries, so materialize real files.
  home.activation.cwalMaterializeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cwal_dir="$HOME/.config/cwal"
    mkdir -p "$cwal_dir"

    for subdir in themes templates; do
      src="${pkgs.cwal}/share/cwal/$subdir"
      dest="$cwal_dir/$subdir"
      mkdir -p "$dest"

      # Replace any existing symlinked entries with regular files.
      # cwal ships read-only theme/template files, so later activations
      # need --remove-destination to swap them out cleanly.
      find "$dest" -type l -delete >/dev/null 2>&1 || true
      cp -r --remove-destination "$src"/. "$dest"/
    done
  '';
}
