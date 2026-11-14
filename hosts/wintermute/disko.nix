# Disk layout for the NEW disk only, applied by nixos-anywhere. The old disk is
# deliberately not declared here, so nothing ever touches it (it stays as the
# fallback system).
{ ... }:

let
  # Compression saves space and writes; noatime avoids a write on every read.
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  disko.devices.disk.wintermute = {
    type = "disk";
    # Always by-id: sda/sdb can swap between boots, and a wrong guess would
    # format the old disk.
    device = "/dev/disk/by-id/ata-WDC_WD20EFRX-68EUZN0_WD-WCC4M0KVF806";
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
