{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      # The XPS's Synaptics I2C-HID touchpad (`ven_06cb:00-06cb:d01d-touchpad`
      # in `hyprctl devices`) tracks noticeably less fluidly under libinput's
      # default "adaptive" pointer-acceleration curve than a flat, 1:1
      # response gives it. Scoped to this exact device name so it's a no-op
      # on other hosts' touchpads.
      device = [
        {
          name = "ven_06cb:00-06cb:d01d-touchpad";
          accel_profile = "flat";

          # Flat trades libinput's adaptive curve for fluid 1:1 tracking, but
          # with no curve to boost fast swipes the pointer only moves at
          # physical speed - this raises the constant gain flat still applies
          # to compensate. Range is -1.0 to 1.0; bump towards 1.0 if it's
          # still not fast enough.
          sensitivity = 0.5;
        }
      ];
    };
  };
}
