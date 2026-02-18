{
  config,
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
  ];

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
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # SSH is essential for a headless server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Change to false once you've added your SSH key
    };
  };

  users.users.${username}.openssh.authorizedKeys.keyFiles = [
    ../../ssh/public-keys/laptop.pub
    ../../ssh/public-keys/desktop.pub
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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable Container/Docker support (useful for homelabs)
  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = [ "docker" ];

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
