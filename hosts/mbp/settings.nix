{
  username = "birk";

  # Maps to config.systemSettings.*
  system = {
    # Darwin-specific system settings
    # homebrew, yabai, skhd could be added here
  };

  # Maps to config.userSettings.*
  user = {
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
      todoist.enable = true;
      browsers = {
        chrome.enable = true;
        firefox.enable = true;
        default = "chrome";
      };
    };
  };
}
