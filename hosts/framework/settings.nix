{
  username = "birk";

  # Maps to config.systemSettings.*
  system = {
    hyprland.enable = true;
  };

  # Maps to config.userSettings.*
  user = {
    cli = {
      core.enable = true;
      zsh.enable = true;
      git.enable = true;
      jj.enable = true;
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
    terminal.ghostty.enable = true;
    docker.enable = true;
    apps = {
      slack.enable = true;
      obsidian.enable = true;
      browsers = {
        chrome.enable = true;
        firefox.enable = true;
        default = "chrome";
      };
      # Sites that get their own window and desktop entry - see
      # modules/nixos/webapps.nix. Plain SUPER + L is taken by focus-right,
      # so Linear takes the SHIFT variant.
      webapps.sites = {
        linear = {
          url = "https://linear.app";
          icon = ../../icons/webapps/linear.png;
          key = "SHIFT + L";
        };
      };
    };
    hyprland.enable = true;
  };
}
