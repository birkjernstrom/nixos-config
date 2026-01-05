{ config, lib, ... }:

with lib; let
  cfg = config.userSettings.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      "$mainMod" = "SUPER";

      bind = [
        # Volume control (F1=mute, F2=lower, F3=raise)
        ", F1, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", F2, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", F3, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"

        # Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more
        "$mainMod, return, exec, $terminal"
        "$mainMod, B, exec, google-chrome-stable"
        "$mainMod, S, exec, slack"
        "$mainMod, X, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, exec, cliphist list | wofi --show dmenu | cliphist decode | wl-copy"
        "$mainMod SHIFT, V, togglefloating,"
        "$mainMod, space, exec, $menu"
        "$mainMod, P, pseudo," # dwindle
        "$mainMod SHIFT, J, togglesplit," # dwindle

        # Move focus with mainMod + arrow keys
        "$mainMod, h, movefocus, l"
        "$mainMod, j, movefocus, d"
        "$mainMod, k, movefocus, u"
        "$mainMod, l, movefocus, r"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
      ];
    };
  };
}
