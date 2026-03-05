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
      find "$dest" -type l -delete >/dev/null 2>&1 || true
      cp -r "$src"/. "$dest"/
    done
  '';
}
