{ lib, ... }:
{
  disko.devices = {
    disk = {
      # 1. Main System Drive (SSD) - 240GB Kingston
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B778337F56F";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      # 2. Data Drives (1TB x 2) - ZFS Mirror
      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-MB001000GWJAN_29H1K2VHFE0F";
        content = {
          type = "zfs";
          pool = "dpool";
        };
      };
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-MB001000GWJAN_29H1K2VOFE0F";
        content = {
          type = "zfs";
          pool = "dpool";
        };
      };

      # 3. Media Drives (4TB x 2) - ZFS Stripe
      media1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-MB004000GWKGV_V6GZ22DS";
        content = {
          type = "zfs";
          pool = "mpool";
        };
      };
      media2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-MB004000GWKGV_V6GZ287S";
        content = {
          type = "zfs";
          pool = "mpool";
        };
      };
    };

    # ZFS Pool Definitions
    zpool = {
      dpool = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/data";
      };

      mpool = {
        type = "zpool";
        mode = ""; # Stripe
        rootFsOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/media";
      };
    };
  };
}