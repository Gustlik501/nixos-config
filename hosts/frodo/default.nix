{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
let
  profilarrCompose = pkgs.writeText "docker-compose.yml" ''
    services:
      profilarr:
        image: santiagosayshey/profilarr:latest
        container_name: profilarr
        restart: unless-stopped
        ports:
          - "5678:6868"
        volumes:
          - /var/lib/profilarr:/config
        environment:
          - TZ=Europe/Ljubljana
  '';
in
{
  imports = [
    ./disk-config.nix
    ../../profiles/base.nix
    ../../modules/services/wireguard.nix
    ../../modules/services/glance.nix
    ../../modules/services/media.nix
    ../../modules/services/caddy.nix
    ../../modules/services/adguard.nix
    ../../modules/services/vaultwarden.nix
    ../../modules/services/postgresql.nix
    ../../modules/services/pi-web.nix
    ../../modules/services/pi-web-frodo-storage.nix
  ];

  services.pi-web = {
    enable = true;
    gateway.enable = true;
    extraPackages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];
  };

  networking.hostName = "frodo";
  networking.hostId = "8425e349"; # Required for ZFS

  # ZFS: Add nofail so system doesn't panic if pools are slow
  fileSystems."/data" = {
    device = "dpool";
    fsType = "zfs";
    options = [
      "zfsutil"
      "nofail"
    ];
  };

  fileSystems."/media" = {
    device = "mpool";
    fsType = "zfs";
    options = [
      "zfsutil"
      "nofail"
    ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ZFS Support
  boot.supportedFilesystems = [ "zfs" ];
  # Both datasets are explicitly mounted by fileSystems above (with zfsutil).
  # Do not also run `zfs mount -a`: it races data.mount/media.mount at boot.
  # Revisit this if adding native ZFS datasets without fileSystems entries.
  systemd.services.zfs-mount.enable = false;
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # SSH is essential for a headless server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  users.users = lib.mkMerge [
    {
      ${username} = {
        openssh.authorizedKeys.keyFiles = [
          ../../ssh/laptop.pub
          ../../ssh/desktop.pub
          ../../ssh/phone.pub
          ../../ssh/work.pub
        ];
        # Docker is managed by root-owned systemd units. Interactive access uses
        # sudo; membership in the docker group would bypass sudo authentication.
      };
    }
    (lib.mkIf config.services.pi-web.gateway.enable {
      pi-web-desktop.openssh.authorizedKeys.keyFiles = [ ../../ssh/desktop.pub ];
      pi-web-laptop.openssh.authorizedKeys.keyFiles = [ ../../ssh/laptop.pub ];
    })
  ];

  # NVIDIA 1050ti configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false; # 1050ti is too old for the open kernel modules
    nvidiaPersistenced = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  # Headless compute: ensure NVIDIA modules are loaded even without X/Wayland.
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Enable Container/Docker support (useful for homelabs)
  virtualisation.docker.enable = true;

  # Profilarr Service
  systemd.services.profilarr = {
    description = "Profilarr Docker Compose Service";
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # We don't need a WorkingDirectory since we pass the file explicitly
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${profilarrCompose} -p profilarr up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${profilarrCompose} -p profilarr down";
    };
  };

  # Basic Server Tools
  environment.systemPackages = with pkgs; [
    wget
    curl
    pciutils
    glances
    lm_sensors
    kitty.terminfo # Fixes "xterm-kitty" error when SSHing from Kitty
    cudaPackages.cudatoolkit
    docker-compose # Ensure docker-compose binary is available
    # Add any other server-specific tools here (e.g., iotop, ncdu)
  ];

  # Firewall settings for common services
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
      5678 # Profilarr
    ]; # SSH, HTTP, HTTPS
  };
}
