{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    yabai
  ];

  services.yabai = {
    enable = true;

    config = {
      mouse_follows_focus = "on";
      focus_follows_mouse = "off";
      window_origin_display = "default";
      window_placement = "second_child";
      window_zoom_persist = "on";
      window_topmost = "off";
      window_shadow = "on";
      window_animation_duration = 0;
      window_animation_frame_rate = 120;
      window_opacity_duration = 0.0;
      active_window_opacity = 1.0;
      normal_window_opacity = 0.90;
      window_opacity = "off";
      insert_feedback_color = "0xffd75f5f";
      active_window_border_color = "0xff775759";
      normal_window_border_color = "0xff555555";
      window_border_width = 4;
      window_border_radius = 12;
      window_border_blur = "off";
      window_border_hidpi = "on";
      window_border = "off";
      split_ratio = 0.50;
      split_type = "auto";
      auto_balance = "off";
      top_padding = 12;
      bottom_padding = 12;
      left_padding = 12;
      right_padding = 12;
      window_gap = 06;
      layout = "bsp";
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };

    extraConfig = ''
      # Apps to ignore from tiling
      yabai -m rule --add app="^System Settings$" manage=off
      yabai -m rule --add app="^Finder$" manage=off
      yabai -m rule --add app="^Calculator$" manage=off
      yabai -m rule --add app="^Raycast$" manage=off
      yabai -m rule --add app="^1Password$" manage=off
      yabai -m rule --add app="^Messages$" manage=off
      yabai -m rule --add app="^Digital Colour Meter$" manage=off
      yabai -m rule --add app="^Loom$" manage=off

      # Open apps in particular spaces
      yabai -m rule --add app="^Wezterm" space=1
      yabai -m rule --add app="^Google Chrome" space=2

      yabai -m rule --add app="^Figma" space=3
      yabai -m rule --add app="^Pitch" space=3

      yabai -m rule --add app="^Discord" space=4

      yabai -m rule --add app="^Cron" space=5
      yabai -m rule --add app="^Todoist" space=5

      yabai -m rule --add app="^Spotify" space=6
    '';
  };
}
