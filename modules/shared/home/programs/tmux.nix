{ config, pkgs, ... }:

let
  tokyo-night-tmux = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tokyo-night";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "janoamaral";
      repo = "tokyo-night-tmux";
      rev = "c3bc283cceeefaa7e5896878fe20711f466ab591";
      sha256 = "sha256-3rMYYzzSS2jaAMLjcQoKreE0oo4VWF9dZgDtABCUOtY=";
    };
  };
in
{
  tmux = {
    enable = true;
    terminal = "xterm-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    prefix = "C-s";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";

    extraConfig = ''
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf

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
    '';

    plugins = with pkgs; [
      # No need to load `sensible` as it is loaded by default
      {
        plugin = tokyo-night-tmux;
        extraConfig = ''
          set -g @tokyo-night-tmux_window_id_style digital
          set -g @tokyo-night-tmux_pane_id_style hsquare
          set -g @tokyo-night-tmux_zoom_id_style dsquare
        '';
      }
      tmuxPlugins.tmux-fzf
      tmuxPlugins.fzf-tmux-url
      tmuxPlugins.t-smart-tmux-session-manager
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
