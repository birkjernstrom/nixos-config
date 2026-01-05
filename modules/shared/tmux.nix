{ config, pkgs, lib, theme, ... }:

with lib; let
  cfg = config.userSettings.cli.tmux;
  colors = theme.tmux;
in
{
  options.userSettings.cli.tmux.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Enable tmux configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      tmux
      tmuxp
    ];

    home.file = {
      ".config/tmuxp" = {
        source = ../../dotfiles/tmuxp;
        recursive = true;
      };
    };

    programs.tmux = {
      enable = true;
      terminal = "xterm-ghostty";
      shell = "${pkgs.zsh}/bin/zsh";
      prefix = "C-s";
      baseIndex = 1;
      mouse = true;
      keyMode = "vi";
      escapeTime = 10;

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

        # Theme colors - vesper style
        # Use 'default' bg to respect terminal transparency
        set -g status-style "bg=default fg=${colors.fg_muted}"

        # Make pane backgrounds transparent
        set -g window-style "bg=default"
        set -g window-active-style "bg=default"
        set -g status-left "#[fg=${colors.accent},bold] #S #[fg=${colors.fg_dim}]│ "
        set -g status-right "#[fg=${colors.fg_muted}]%-I:%M %p "
        set -g status-left-length 50
        set -g status-right-length 50

        # Window status
        setw -g window-status-format "#[fg=${colors.fg_dim}] #I #W "
        setw -g window-status-current-format "#[fg=${colors.fg},bold] #I #W "

        # Pane borders
        set -g pane-border-style "fg=${colors.border}"
        set -g pane-active-border-style "fg=${colors.accent}"

        # Message styling
        set -g message-style "bg=${colors.elevated} fg=${colors.fg}"
        set -g message-command-style "bg=${colors.elevated} fg=${colors.fg}"

        # Copy mode styling
        set -g mode-style "bg=${colors.selected} fg=${colors.fg}"

        # Clock
        set -g clock-mode-colour "${colors.accent}"

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
  };
}
