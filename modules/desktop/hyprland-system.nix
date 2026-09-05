# The system half of Hyprland: the compositor package and the udev rules that
# let brightnessctl work without root.
{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      hyprland
      kitty
      brightnessctl
    ];

    # Ships udev rules that hand the `video` group write access to
    # /sys/class/backlight/*/brightness, so brightnessctl works unprivileged.
    services.udev.packages = [ pkgs.brightnessctl ];
  };
}
