{ config, pkgs, ... }:

let
  minimal-tmux-status = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "minimal-tmux-status";
    rtpFilePath = "minimal.tmux";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "niksingh710";
      repo = "minimal-tmux-status";
      rev = "131306e6924a8e71dfc6be20dd1a10441248c690";
      sha256 = "sha256-cwWoKsiDLSlSLis5tzqP2kFwTbl9PlzMYNdo2lDk0So=";
    };
  };
in
{
  tmux = {
    enable = true;
    terminal = "screen-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    prefix = "C-s";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    escapeTime = 10;

    extraConfig = ''
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf

      set-option -a terminal-features 'xterm-256color:RGB'

      # Create panes
      unbind %
      bind '|' split-window -h

      unbind '"'
      bind '-' split-window -v

      # Resize vim-style
      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5

      # m to Zoom
      bind -r m resize-pane -Z

      # Moving windows
      bind-key -n C-S-Left swap-window -t -1
      bind-key -n C-S-Right swap-window -t +1

      # Vim bindings in copy mode
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # Statusbar on top
      set -g status-position top

      # Sesh
      bind-key "T" run-shell "sesh connect \"$(
        sesh list | fzf-tmux -p 55%,60% \
            --no-sort --border-label ' sesh ' --prompt '⚡  ' \
            --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
            --bind 'tab:down,btab:up' \
            --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
            --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
            --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
            --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
            --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
            --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)'
        )\""
    '';

    plugins = with pkgs; [
      # No need to load `sensible` as it is loaded by default
      {
        plugin = minimal-tmux-status;
        extraConfig = ''
          set -g @minimal-tmux-bg "#8ba4b0"  # Kanagawa dragonBlue2
          set -g @minimal-tmux-justify "centre"
          set -g @minimal-tmux-indicator-str "  tmux  "
          set -g @minimal-tmux-indicator true
          set -g @minimal-tmux-status "top"
        '';
      }
      tmuxPlugins.tmux-fzf
      tmuxPlugins.fzf-tmux-url
      {
        plugin = tmuxPlugins.tmux-thumbs;
        extraConfig = ''
          set -g @thumbs-reverse enabled
          set -g @thumbs-unique enabled
        '';
      }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
    ];

  };
}
