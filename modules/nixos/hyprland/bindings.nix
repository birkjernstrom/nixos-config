{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
  hypr = import ./lib.nix { inherit lib; };
  inherit (hypr) bind bindWith mod lua exec execLua workspaceCount;

  # Hardware keys: repeat while held and stay live on the lock screen.
  hwBind = description: keys: cmd: bindWith { locked = true; repeating = true; } description keys (exec cmd);

  # Same, minus the repeat: a toggle held down would just flap on and off.
  toggleBind = description: keys: cmd: bindWith { locked = true; } description keys (exec cmd);

  volumeMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  volumeDown = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
  volumeUp = "sh -c " + escapeShellArg ''
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q '\[MUTED\]'; then
      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5% &&
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    else
      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
    fi
  '';

  # -e4 gives a perceptually even ramp, -n2 keeps the panel from going black.
  brightnessDown = "brightnessctl -e4 -n2 set 5%-";
  brightnessUp = "brightnessctl -e4 -n2 set 5%+";

  # Workspaces 1-8. Which monitor each one lives on is fixed by
  # ./workspaces.nix, so these binds always land on the same physical screen.
  workspaceBinds = concatMap (i:
    let key = toString i; in [
      (bind "Workspaces: Go to workspace ${key}" (mod key) (lua "hl.dsp.focus({ workspace = ${key} })"))
      (bind "Workspaces: Move window to workspace ${key}" (mod "SHIFT + ${key}") (lua "hl.dsp.window.move({ workspace = ${key} })"))
    ]) (range 1 workspaceCount);
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings.bind = [
      # Volume (F1=mute, F2=lower, F3=raise). Both keysyms are bound for the
      # same reason the brightness keys below bind both: one physical key sends
      # F1-F3 in one fn-lock state and the XF86Audio* media keysyms in the
      # other, and only the F-key half used to be here - so the keys went dead
      # whenever fn-lock was the other way round.
      (toggleBind "Media: Toggle mute" "F1" volumeMute)
      (toggleBind null "XF86AudioMute" volumeMute)
      (hwBind "Media: Volume down" "F2" volumeDown)
      (hwBind null "XF86AudioLowerVolume" volumeDown)
      (hwBind "Media: Volume up" "F3" volumeUp)
      (hwBind null "XF86AudioRaiseVolume" volumeUp)

      # Screen brightness (F7=lower, F8=raise). The Fn-layer keysyms are
      # bound as well, so the keys work in either fn-lock state.
      (hwBind "Media: Brightness down" "F7" brightnessDown)
      (hwBind "Media: Brightness up" "F8" brightnessUp)
      (hwBind null "XF86MonBrightnessDown" brightnessDown)
      (hwBind null "XF86MonBrightnessUp" brightnessUp)

      (bind "Apps: Open terminal" (mod "return") (execLua "terminal"))
      (bind "Apps: Open file manager" (mod "E") (execLua "fileManager"))
      (bind "Launcher: Open Pathway" (mod "space") (execLua "menu"))
      (bind "Launcher: Open clipboard history" (mod "V") (execLua "clipboard"))
      (bind "Launcher: Show keybinds" (mod "SHIFT + K") (exec "qs ipc call pathway keybinds"))

      (bind "Windows: Close window" (mod "W") (lua "hl.dsp.window.close()"))
      (bind "Windows: Toggle floating window" (mod "SHIFT + V") (lua ''hl.dsp.window.float({ action = "toggle" })''))
      (bind "Windows: Toggle pseudo-tiling" (mod "P") (lua "hl.dsp.window.pseudo()"))
      (bind "Windows: Toggle split direction" (mod "SHIFT + J") (lua ''hl.dsp.layout("togglesplit")''))

      # Move focus with mainMod + vim keys
      (bind "Windows: Focus window left" (mod "h") (lua ''hl.dsp.focus({ direction = "left" })''))
      (bind "Windows: Focus window below" (mod "j") (lua ''hl.dsp.focus({ direction = "down" })''))
      (bind "Windows: Focus window above" (mod "k") (lua ''hl.dsp.focus({ direction = "up" })''))
      (bind "Windows: Focus window right" (mod "l") (lua ''hl.dsp.focus({ direction = "right" })''))

      (bind "Monitors: Focus left monitor" (mod "bracketleft") (lua ''hl.dsp.focus({ monitor = "l" })''))
      (bind "Monitors: Focus right monitor" (mod "bracketright") (lua ''hl.dsp.focus({ monitor = "r" })''))
      (bind "Monitors: Move window to left monitor" (mod "SHIFT + bracketleft") (lua ''hl.dsp.window.move({ monitor = "l" })''))
      (bind "Monitors: Move window to right monitor" (mod "SHIFT + bracketright") (lua ''hl.dsp.window.move({ monitor = "r" })''))
      (bind "Monitors: Move workspace to left monitor" (mod "CTRL + bracketleft") (lua ''hl.dsp.workspace.move({ monitor = "l" })''))
      (bind "Monitors: Move workspace to right monitor" (mod "CTRL + bracketright") (lua ''hl.dsp.workspace.move({ monitor = "r" })''))

      (bind "System: Switch keyboard layout" (mod "SHIFT + space") (exec "hyprctl switchxkblayout all next"))
      (bind "System: Log out" (mod "SHIFT + CTRL + Q") (lua "hl.dsp.exit()"))
    ]
    # Switch workspaces with mainMod + [1-8], move the active window there
    # with mainMod + SHIFT + [1-8]
    ++ workspaceBinds;
  };
}
