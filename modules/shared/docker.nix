# Docker module (system-level)
# Installs Docker and lazydocker.
{ config, lib, pkgs, settings, isDarwin, ... }:

let
  cfg = settings.user.docker or {};
  dockerEnabled = cfg.enable or false;
  username = settings.user.name;
in
{
  config = lib.mkIf dockerEnabled (
    if isDarwin then {
      # Darwin: install docker CLI + colima (lightweight runtime) + lazydocker
      # Colima provides the Docker daemon without Docker Desktop GUI
      homebrew.brews = [
        "docker"
        "colima"
        "lazydocker"
      ];
    } else {
      # NixOS: enable docker service and configure home-manager
      virtualisation.docker.enable = true;

      # Add user to docker group
      users.users.${username}.extraGroups = [ "docker" ];

      home-manager.users.${username} = {
        # Install lazydocker
        home.packages = [ pkgs.lazydocker ];
      };
    }
  );
}
