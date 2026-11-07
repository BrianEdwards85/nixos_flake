# Disk layout for the NEW disk only. The existing disk is deliberately not
# declared here, so nixos-anywhere never touches it (it stays as a backup).
{ ... }:

{
  # TODO: replace with the real /dev/disk/by-id/... path of the new disk.
  # Always use by-id: sda/sdb can swap in the installer, and a wrong guess
  # would format the old disk.
  disko.devices.disk.free-side = {
    type = "disk";
    device = "/dev/disk/by-id/DUMMY-REPLACE-ME";
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
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
