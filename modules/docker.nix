# Container runtime.
{ ... }:

{
  virtualisation.docker = {
    enable = true;

    # Without limits a container's log grows until the container is removed.
    # Applies to containers created after the daemon restarts, so existing ones keep
    # their old setting until Ansible recreates them.
    daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
    };
  };
}
