{
  username = "birk";

  # Maps to config.systemSettings.*
  system = {
    hyprland.enable = true;
    primo.enable = true;
    tailscale.enable = true;
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
        chrome = {
          enable = true;
          # Force-installed via Chrome's managed policy. The ID is the last
          # path segment of the extension's Chrome Web Store URL.
          extensions = [
            "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
          ];
        };
        firefox.enable = true;
        default = "chrome";
      };
      # Sites that get their own window and desktop entry - see
      # modules/nixos/webapps.nix. Launched on SUPER + SHIFT + <letter>; the
      # plain SUPER + letter combos are window management (L focuses right,
      # W closes).
      webapps.sites = {
        claude = {
          url = "https://claude.ai";
          icon = ../../icons/webapps/claude.png;
          key = "SHIFT + C";
        };
        chatgpt = {
          # The derived name would be "Chatgpt".
          name = "ChatGPT";
          url = "https://chatgpt.com";
          icon = ../../icons/webapps/chatgpt.png;
          key = "SHIFT + A";
        };
        linear = {
          url = "https://linear.app";
          icon = ../../icons/webapps/linear.png;
          key = "SHIFT + L";
        };
        gmail = {
          url = "https://mail.google.com";
          icon = ../../icons/webapps/gmail.png;
          key = "SHIFT + G";
        };
        whatsapp = {
          # The derived name would be "Whatsapp".
          name = "WhatsApp";
          url = "https://web.whatsapp.com";
          icon = ../../icons/webapps/whatsapp.png;
          key = "SHIFT + W";
        };
      };
    };
    hyprland.enable = true;
  };
}
