{ config, lib, pkgs, ... }:

with lib; let
  cfg = config.userSettings.quickshell;
in
{
  options.userSettings.quickshell.enable = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Quickshell (bar + Pathway command menu)";
  };

  config = mkIf cfg.enable {
    home.packages = [
      # nixpkgs builds with NETWORK, SERVICE_UPOWER and HYPRLAND_* all defaulting
      # to ON, so Quickshell.Networking/UPower/Hyprland are available. No flake
      # input is needed.
      pkgs.quickshell

      # qmlls / qmlformat / qmllint for editing the QML.
      pkgs.qt6.qtdeclarative
    ];

    # Until the shell reaches v1, ~/.config/quickshell is a hand-made symlink to
    # ./quickshell in this repo so edits hot-reload without a rebuild. Swap the
    # symlink for this once the config stops changing hourly:
    #
    # xdg.configFile."quickshell" = {
    #   source = ../../../quickshell;
    #   recursive = true;
    # };
  };
}
