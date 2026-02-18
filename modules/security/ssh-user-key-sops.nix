{
  config,
  lib,
  username ? null,
  ...
}:
let
  cfg = config.my.security.sopsSshUserKey;
  userName =
    if cfg.user != null then
      cfg.user
    else if username != null then
      username
    else
      throw "Set my.security.sopsSshUserKey.user or pass `username` in specialArgs.";
in
{
  options.my.security.sopsSshUserKey = {
    enable = lib.mkEnableOption "manage per-host SSH user private key via sops-nix";

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "gustl";
      description = "User account that should own `/home/<user>/.ssh/id_ed25519`.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "../../secrets/laptop/ssh-user.yaml";
      description = "Encrypted SOPS file containing the `ssh_user_ed25519_key` key.";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the host age private key used by sops-nix at runtime.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.keyFile = cfg.ageKeyFile;
      defaultSopsFile = cfg.sopsFile;
      defaultSopsFormat = "yaml";

      secrets.ssh_user_ed25519_key = {
        path = "/home/${userName}/.ssh/id_ed25519";
        owner = userName;
        group = userName;
        mode = "0600";
      };
    };

    systemd.tmpfiles.rules = [
      "d /home/${userName}/.ssh 0700 ${userName} ${userName} -"
    ];
  };
}
