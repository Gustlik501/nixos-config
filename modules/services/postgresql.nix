{
  config,
  lib,
  pkgs,
  ...
}:
let
  databaseUser = "gustl";
  databaseNames = [
    "gsevc_dev"
    "gsevc_prod"
  ];
in
{
  sops.secrets.postgresql_gustl_password = { };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    settings = {
      port = 5432;
      password_encryption = "scram-sha-256";
    };
    authentication = lib.mkBefore ''
      host all ${databaseUser} samenet scram-sha-256
    '';
    ensureDatabases = databaseNames;
    ensureUsers = [
      {
        name = databaseUser;
        ensureClauses = {
          login = true;
          password = "SCRAM-SHA-256$4096:nkB1zzprga+PY3QnVesDrg==$lC5sCxobWAJ/9ui59MbXpnLfxUmwoW7EIxge95xaonw=:tBtmlypF+YwAsVGNmaTTBogNkYkyBIiAwcRocDp3ssA=";
        };
      }
    ];
  };

  systemd.services.postgresql-setup.script = lib.mkAfter (
    lib.concatMapStringsSep "\n" (
      databaseName: ''
        psql -d postgres -tAc 'ALTER DATABASE "${databaseName}" OWNER TO "${databaseUser}";'
      ''
    ) databaseNames
  );

  networking.firewall.allowedTCPPorts = [ config.services.postgresql.settings.port ];
}
