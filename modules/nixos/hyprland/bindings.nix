{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) bind bindWith mod lua exec execLua;

  # Hardware keys: repeat while held and stay live on the lock screen.
  hwBind = keys: cmd: bindWith { locked = true; repeating = true; } keys (exec cmd);

  # -e4 gives a perceptually even ramp, -n2 keeps the panel from going black.
  brightnessDown = "brightnessctl -e4 -n2 set 5%-";
  brightnessUp = "brightnessctl -e4 -n2 set 5%+";

  # Workspaces 1-10, with 10 bound to the "0" key.
  workspaceBinds = concatMap (i:
    let key = if i == 10 then "0" else toString i; in [
      (bind (mod key) (lua "hl.dsp.focus({ workspace = ${toString i} })"))
      (bind (mod "SHIFT + ${key}") (lua "hl.dsp.window.move({ workspace = ${toString i} })"))
    ]) (range 1 10);
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.bind = [
      # Volume control (F1=mute, F2=lower, F3=raise)
      (bind "F1" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      (bind "F2" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
      (bind "F3" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))

      # Screen brightness (F7=lower, F8=raise). The Fn-layer keysyms are
      # bound as well, so the keys work in either fn-lock state.
      (hwBind "F7" brightnessDown)
      (hwBind "F8" brightnessUp)
      (hwBind "XF86MonBrightnessDown" brightnessDown)
      (hwBind "XF86MonBrightnessUp" brightnessUp)

      # Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
      (bind (mod "return") (execLua "terminal"))
      (bind (mod "W") (lua "hl.dsp.window.close()"))
      (bind (mod "SHIFT + CTRL + Q") (lua "hl.dsp.exit()"))
      (bind (mod "E") (execLua "fileManager"))
      (bind (mod "V") (exec "cliphist list | wofi --show dmenu | cliphist decode | wl-copy"))
      (bind (mod "SHIFT + V") (lua ''hl.dsp.window.float({ action = "toggle" })''))
      (bind (mod "space") (execLua "menu"))
      (bind (mod "SHIFT + space") (exec "hyprctl switchxkblayout all next"))
      (bind (mod "P") (lua "hl.dsp.window.pseudo()")) # dwindle
      (bind (mod "SHIFT + J") (lua ''hl.dsp.layout("togglesplit")'')) # dwindle

      # Move focus with mainMod + vim keys
      (bind (mod "h") (lua ''hl.dsp.focus({ direction = "left" })''))
      (bind (mod "j") (lua ''hl.dsp.focus({ direction = "down" })''))
      (bind (mod "k") (lua ''hl.dsp.focus({ direction = "up" })''))
      (bind (mod "l") (lua ''hl.dsp.focus({ direction = "right" })''))

      # Focus monitor left/right
      (bind (mod "bracketleft") (lua ''hl.dsp.focus({ monitor = "l" })''))
      (bind (mod "bracketright") (lua ''hl.dsp.focus({ monitor = "r" })''))

      # Move window to monitor left/right
      (bind (mod "SHIFT + bracketleft") (lua ''hl.dsp.window.move({ monitor = "l" })''))
      (bind (mod "SHIFT + bracketright") (lua ''hl.dsp.window.move({ monitor = "r" })''))

      # Move entire workspace to other monitor
      (bind (mod "CTRL + bracketleft") (lua ''hl.dsp.workspace.move({ monitor = "l" })''))
      (bind (mod "CTRL + bracketright") (lua ''hl.dsp.workspace.move({ monitor = "r" })''))
    ]
    # Switch workspaces with mainMod + [0-9], move the active window there
    # with mainMod + SHIFT + [0-9]
    ++ workspaceBinds;
  };
}
