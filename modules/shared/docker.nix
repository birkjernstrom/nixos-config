# Docker module (system-level)
# Installs Docker, lazydocker, and adds waybar status on NixOS
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

        # Add waybar custom module for docker
        programs.waybar.settings.mainBar = {
          "modules-right" = lib.mkBefore [ "custom/docker" ];

          "custom/docker" = {
            format = "󰡨 {}";
            exec = ''${pkgs.docker}/bin/docker ps -q 2>/dev/null | wc -l | tr -d ' ' '';
            interval = 5;
            on-click = "ghostty -e lazydocker";
            tooltip-format = "Running containers: {}";
          };
        };

        # Add waybar styling for docker module
        programs.waybar.style = lib.mkAfter ''
          #custom-docker {
            padding: 0 12px;
            margin: 4px 2px;
            border-radius: 6px;
            background: @bg-selection;
            color: @cyan;
          }
        '';
      };
    }
  );
}
