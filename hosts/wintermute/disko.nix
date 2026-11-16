# Disk layout for the SSD (the KingFast), applied by nixos-anywhere. The other disks are
# deliberately not declared here, so nothing ever touches them. The disk's name below sets the
# partition labels (disk-wintermute-ssd-*), which the system mounts by: they must differ from
# the labels of any other disk in the machine (the WD Red has disk-wintermute-*).
{ ... }:

let
  # Compression saves space and writes; noatime avoids a write on every read.
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  disko.devices.disk.wintermute-ssd = {
    type = "disk";
    # Always by-id: sda/sdb can swap between boots, and a wrong guess would
    # format the old disk.
    device = "/dev/disk/by-id/ata-KingFast_E010172Y00060";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/@" = {
                mountpoint = "/";
                inherit mountOptions;
              };
              "/@home" = {
                mountpoint = "/home";
                inherit mountOptions;
              };
              "/@nix" = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              "/@log" = {
                mountpoint = "/var/log";
                inherit mountOptions;
              };
              "/@srv" = {
                mountpoint = "/srv";
                inherit mountOptions;
              };
            };
          };
        };
      };
    };
  };
}
