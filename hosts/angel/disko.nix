# Disk layout, applied by nixos-anywhere. This wipes the whole disk.
#
# One Btrfs filesystem with a subvolume for each of /, /home, /nix, /var/log and
# /srv, so each can be snapshotted, sent or rolled back on its own.
{ ... }:

let
  # zstd compression saves space and, on a spinning disk, reads. noatime stops every
  # read from causing a write.
  options = [
    "compress=zstd"
    "noatime"
  ];
in
{
  # by-id, never sda: the letters can swap in the installer, and a wrong guess
  # would format another disk.
  disko.devices.disk.angel = {
    type = "disk";
    device = "/dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M0KVF806";
    content = {
      type = "gpt";
      partitions = {
        # 1 GB: systemd-boot keeps a kernel and initrd on it for each generation
        ESP = {
          size = "1G";
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
            # -f: overwrite whatever filesystem was on the disk before
            extraArgs = [
              "-f"
              "-L"
              "angel"
            ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = options;
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = options;
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = options;
              };
              "/log" = {
                mountpoint = "/var/log";
                mountOptions = options;
              };
              "/srv" = {
                mountpoint = "/srv";
                mountOptions = options;
              };
            };
          };
        };
      };
    };
  };
}
