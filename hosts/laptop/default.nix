{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
    ];
  };

  boot.initrd.kernelModules = [ "i915" ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      ovmf.enable = true; # UEFI firmware
      swtpm.enable = true; # vTPM for Win11
      runAsRoot = false; # user session libvirt
    };

  };

  programs.virt-manager.enable = true;

  # Your user to groups
  users.users.gustl.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  # Handy tools/ISOs available on host
  environment.systemPackages = with pkgs; [
    virtiofsd # (mainly for Linux guests)
    virtio-win # Windows VirtIO drivers ISO
    spice-gtk # SPICE client support
  ];

}
