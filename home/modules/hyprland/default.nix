{ config, lib, ... }:

with lib; let
  feat = config.features.hyprland;
in
{
  imports = [
    ./autostart.nix
    ./bindings.nix
  ];

  options.features.hyprland.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Hyperland (NixOS)";
  };

  config = mkIf feat.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = ",preferred,auto,auto";
        "$terminal" = "ghostty";
        "$fileManager" = "dolphin";
        "$menu" = "wofi --show drun";
        "env" = [
          "XCURSOR_SIZE,24"
          "HYPERCURSOR_SIZE,24"
        ];
        "windowrule" = [
          # Ignore maximize requests from apps. You'll probably like this.
          "suppressevent maximize, class:.*"
          # Fix some dragging issues with XWayland
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];
        input = {
          repeat_delay = 200;
          repeat_rate = 100;
        };
      };
    };
  };
}
