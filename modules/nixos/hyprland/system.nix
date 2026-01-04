{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.systemSettings.hyprland;
in
{
  options.systemSettings.hyprland.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Hyprland window manager (system-level)";
  };

  config = mkIf cfg.enable {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      hyprland
      kitty
      waybar
      wofi
    ];
  };
}
