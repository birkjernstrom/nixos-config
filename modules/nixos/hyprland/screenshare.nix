{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprland-preview-share-picker
      slurp
    ];

    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
        custom_picker_binary = ${pkgs.hyprland-preview-share-picker}/bin/hyprland-preview-share-picker
      }
    '';
  };
}
