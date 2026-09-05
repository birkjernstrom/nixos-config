# tmux, with sesh for session switching.
#
# Status bar colours come from Stylix's tmux target; only layout and bindings
# are set here.
{
  flake.modules.homeManager.base = { pkgs, ... }: {
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

        # Status bar colours come from Stylix's tmux target.
        # Keep pane backgrounds transparent so the terminal shows through.
        set -g window-style "bg=default"
        set -g window-active-style "bg=default"
        set -g status-left-length 50
        set -g status-right-length 50

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
