{ config, lib, pkgs, ... }:

# Screen recording with an optional picture-in-picture webcam, after Omarchy's
# omarchy-capture-screenrecording. The webcam is not composited by the
# recorder: it is an mpv window pinned to the corner of the screen (see the
# WebcamOverlay window rules below), and the recording simply captures it.

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) bind mod exec;

  screenrecord = pkgs.writeShellApplication {
    name = "screenrecord";
    # gpu-screen-recorder comes from the system (systemSettings.hyprland), which
    # pairs it with the setcap'd gsr-kms-server it needs to capture outputs.
    runtimeInputs = with pkgs; [ coreutils gnugrep procps jq slurp v4l-utils mpv ffmpeg libnotify xdg-user-dirs ];
    text = builtins.readFile ./scripts/screenrecord.sh;
  };

  webcamResize = pkgs.writeShellApplication {
    name = "screenrecord-webcam-resize";
    runtimeInputs = with pkgs; [ coreutils jq ];
    text = builtins.readFile ./scripts/screenrecord-webcam-resize.sh;
  };

  # The 8:9 portrait presets scale from monitor height, so the overlay takes the
  # same share of a 1080p panel as of a HiDPI one. screenrecord-webcam-resize
  # re-anchors it to the recorded region right after it maps.
  overlayPreset = size: w: h: {
    name = "webcam-overlay-${size}";
    match.class = "^WebcamOverlay-${size}$";
    size = [ w h ];
    move = [ "(monitor_w-${w}-40)" "(monitor_h-${h}-40)" ];
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ screenrecord webcamResize ];

    wayland.windowManager.hyprland.settings = {
      window_rule = [
        (overlayPreset "small" "(monitor_h*4/25)" "(monitor_h*9/50)")
        (overlayPreset "medium" "(monitor_h*2/9)" "(monitor_h/4)")
        (overlayPreset "large" "(monitor_h*3/10)" "(monitor_h*27/80)")
        {
          # Floating, on every workspace, never stealing focus, and exempt from
          # dimming/transparency - it has to look the same in the recording.
          name = "webcam-overlay";
          match = {
            class = "^WebcamOverlay-(small|medium|large)$";
            title = "^WebcamOverlay$";
          };
          float = true;
          pin = true;
          no_initial_focus = true;
          no_dim = true;
          opacity = "1 1";
        }
      ];

      bind = [
        # Press once to pick what to record, again to stop.
        (bind (mod "SHIFT + R") (exec "screenrecord --with-webcam"))
        (bind (mod "ALT + R") (exec "screenrecord"))
        (bind (mod "ALT + bracketleft") (exec "screenrecord-webcam-resize smaller"))
        (bind (mod "ALT + bracketright") (exec "screenrecord-webcam-resize larger"))
      ];
    };
  };
}
