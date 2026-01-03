{ config, pkgs, lib, inputs, settings, isDarwin, ... }:

{
  imports = [
    ../../home
  ];

  config = {
    features = {
      cli = {
        core.enable = true;
        zsh.enable = true;
        git.enable = true;
        tmux.enable = true;
        nvim.enable = true;
      };
      programming = {
        languages = {
          python.enable = true;
          typescript.enable = true;
          go.enable = true;
          rust.enable = true;
        };

        ai.enable = true;
        tools.enable = true;
      };
      hyprland.enable = true;
    };

    home.packages = with pkgs; [ ghostty google-chrome ];
    programs.ghostty.enable = true;

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        text-scaling-factor = 1.0;
      };

      "org/gnome/desktop/input-sources" = {
        xkb-options = [
          "ctrl:nocaps"
        ];
      };

      "org/gnome/desktop/peripherals/keyboard" = {
        delay = 200;
        repeat-interval = 10;
      };
    };
  };
}
