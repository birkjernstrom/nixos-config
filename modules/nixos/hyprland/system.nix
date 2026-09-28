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
      brightnessctl
    ];

    # For the `screenrecord` script (./screenrecord.nix). Also installs the
    # setcap'd gsr-kms-server wrapper gpu-screen-recorder needs to capture a
    # monitor or region directly, without a portal prompt each time.
    programs.gpu-screen-recorder.enable = true;

    # Ships udev rules that hand the `video` group write access to
    # /sys/class/backlight/*/brightness, so brightnessctl works unprivileged.
    services.udev.packages = [ pkgs.brightnessctl ];
  };
}
