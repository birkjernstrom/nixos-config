{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    skhd
  ];

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Start Yabai
      ctrl + alt - s: yabai --start-service
      ctrl + alt - q: yabai --stop-service

      # ############################################################### #
      # WINDOW FOCUS  	   					  #
      # ############################################################### #

      # Window focus (vim directions)
      alt - j : yabai -m window --focus south
      alt - k : yabai -m window --focus north
      alt - h : yabai -m window --focus west
      alt - l : yabai -m window --focus east

      # ############################################################### #
      # WINDOW MOVEMENT	   					  #
      # ############################################################### #

      # Swap windows
      shift + alt - j : yabai -m window --swap south
      shift + alt - k : yabai -m window --swap north
      shift + alt - h : yabai -m window --swap west
      shift + alt - l : yabai -m window --swap east

      # Move windows
      ctrl + alt - j : yabai -m window --warp south
      ctrl + alt - k : yabai -m window --warp north
      ctrl + alt - h : yabai -m window --warp west
      ctrl + alt - l : yabai -m window --warp east

      # macOS Spaces
      shift + alt - 1 : yabai -m window --space 1
      shift + alt - 2 : yabai -m window --space 2
      shift + alt - 3 : yabai -m window --space 3
      shift + alt - 4 : yabai -m window --space 4
      shift + alt - 5 : yabai -m window --space 5
      shift + alt - 6 : yabai -m window --space 6
      shift + alt - 7 : yabai -m window --space 7
      shift + alt - 8 : yabai -m window --space 8
      shift + alt - 9 : yabai -m window --space 9

      # ############################################################### #
      # LAYOUT							  #
      # ############################################################### #

      # Rotate layout clockwise
      shift + alt - r : yabai -m space --rotate 270

      # Swap layout on y-axis
      shift + alt - y : yabai -m space --mirror y-axis

      # Swap layout on x-axis
      shift + alt - x : yabai -m space --mirror x-axis

      # Toggle tiling of window
      shift + alt - t : yabai -m window --toggle float --grid 4:4:1:1:2:2

      # ############################################################### #
      # WINDOW SIZING							  #
      # ############################################################### #

      # Maximize window
      shift + alt - m : yabai -m window --toggle zoom-fullscreen

      # Balance out windows (n for normalize)
      shift + alt - n : yabai -m space --balance

    '';
  };
}
