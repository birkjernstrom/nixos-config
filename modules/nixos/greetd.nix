{ config, pkgs, ... }:

let
  sessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
in
{
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = builtins.concatStringsSep " " [
      "${pkgs.tuigreet}/bin/tuigreet"
      "--time"
      "--asterisks"
      "--remember"
      "--remember-session"
      "--sessions ${sessions}"
      "--cmd start-hyprland"
    ];
  };
}
