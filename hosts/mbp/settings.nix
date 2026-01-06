{
  username = "birk";

  # Maps to config.systemSettings.*
  system = {
    # Darwin-specific system settings
    # homebrew, yabai, skhd could be added here
  };

  # Maps to config.userSettings.*
  user = {
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
    apps = {
      slack.enable = true;
    };
  };
}
