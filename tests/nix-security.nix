# Run: nix eval --offline --impure --json --file tests/nix-security.nix
let
  # Explicit path also covers new modules before they have been added to Git.
  flake = builtins.getFlake ("path:" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  officialKey = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
  numtideKey = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
in
builtins.mapAttrs (
  host: system:
  let
    settings = system.config.nix.settings;
  in
  assert lib.assertMsg (lib.unique settings.trusted-users == [ "root" ])
    "${host}: only root should be a trusted Nix daemon user";
  assert lib.assertMsg (builtins.elem "*" settings.allowed-users)
    "${host}: ordinary users should retain Nix daemon build access";
  assert lib.assertMsg (
    builtins.elem "https://cache.nixos.org/" settings.substituters
    && builtins.elem "https://cache.numtide.com" settings.substituters
    && builtins.elem officialKey settings.trusted-public-keys
    && builtins.elem numtideKey settings.trusted-public-keys
  ) "${host}: both approved binary caches and signing keys must be configured";
  assert lib.assertMsg (settings.require-sigs && settings.sandbox == true)
    "${host}: signature verification and build sandboxing must remain enabled";
  assert lib.assertMsg (
    host != "frodo" || (
      !(builtins.elem "docker" system.config.users.users.gustl.extraGroups)
      && !(builtins.elem "gustl" system.config.users.groups.docker.members)
      && system.config.virtualisation.docker.enable
      && system.config.systemd.services.glance-status.serviceConfig.DynamicUser
      && system.config.systemd.services.glance-status.serviceConfig.NoNewPrivileges
      && system.config.systemd.services.glance-status.serviceConfig.RestrictAddressFamilies == [ "AF_UNIX" ]
    )
  ) "${host}: Docker must remain available to system services, not directly to gustl or the status collector";
  assert lib.assertMsg (
    host != "frodo" || builtins.elem
      "/run/glance-status:/run/glance-status-assets"
      system.config.systemd.services.glance.serviceConfig.BindReadOnlyPaths
  ) "${host}: Glance needs an explicit read-only view of the private status directory";
  assert lib.assertMsg (
    host != "frodo" || (
      !system.config.systemd.services.zfs-mount.enable
      && system.config.fileSystems."/data".enable
      && system.config.fileSystems."/data".device == "dpool"
      && system.config.fileSystems."/data".fsType == "zfs"
      && builtins.elem "zfsutil" system.config.fileSystems."/data".options
      && system.config.fileSystems."/media".enable
      && system.config.fileSystems."/media".device == "mpool"
      && system.config.fileSystems."/media".fsType == "zfs"
      && builtins.elem "zfsutil" system.config.fileSystems."/media".options
    )
  ) "${host}: explicit data/media mounts must not race the native ZFS automounter";
  {
    trustedUsers = lib.unique settings.trusted-users;
    inherit (settings) substituters;
    passed = true;
  }
) flake.nixosConfigurations
