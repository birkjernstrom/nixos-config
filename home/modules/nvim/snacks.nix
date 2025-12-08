{ config, pkgs, inputs, settings, ... }:

{
  programs.nvf.settings.vim = {
    utility.snacks-nvim = {
      enable = true;
      setupOpts = {
        picker = { enable = true; };
        explorer = { enable = true; };
        input = { enable = true; };
        git = { enable = true; };
        gh = { enable = true; };
        gitbrowse = { enable = true; };
      };
    };

    keymaps = [
      # Top Pickers & Explorers
      { mode = "n"; key = "<leader><space>"; action = ":lua Snacks.picker.smart()<CR>"; desc = "Smart Find Files"; }
      { mode = "n"; key = "<leader>fg"; action = ":lua Snacks.picker.grep()<CR>"; desc = "Grep"; }
      { mode = "n"; key = "<leader>,"; action = ":lua Snacks.picker.buffers()<CR>"; desc = "Buffers"; }
      { mode = "n"; key = "<leader>:"; action = ":lua Snacks.picker.command_history()<CR>"; desc = "Command History"; }
      { mode = "n"; key = "<leader>n"; action = ":lua Snacks.picker.notifications()<CR>"; desc = "Notifications"; }
      { mode = "n"; key = "<leader>e"; action = ":lua Snacks.explorer()<CR>"; desc = "File Explorer"; }

      # find
      { mode = "n"; key = "<leader>fb"; action = ":lua Snacks.picker.buffers()<CR>"; desc = "Buffers"; }
      { mode = "n"; key = "<leader>fc"; action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath(\"config\") })<CR>"; desc = "Find Config File"; }
      { mode = "n"; key = "<leader>ff"; action = ":lua Snacks.picker.files()<CR>"; desc = "Find Files"; }
      { mode = "n"; key = "<leader>fp"; action = ":lua Snacks.picker.projects()<CR>"; desc = "Projects"; }
      { mode = "n"; key = "<leader>fr"; action = ":lua Snacks.picker.recent()<CR>"; desc = "Recent"; }
      # git
      { mode = "n"; key = "<leader>gf"; action = ":lua Snacks.picker.git_files()<CR>"; desc = "Find Git Files"; }
      { mode = "n"; key = "<leader>gF"; action = ":lua Snacks.picker.git_log_file()<CR>"; desc = "Git Log File"; }
      { mode = "n"; key = "<leader>gb"; action = ":lua Snacks.picker.git_branches()<CR>"; desc = "Git Branches"; }
      { mode = "n"; key = "<leader>gl"; action = ":lua Snacks.picker.git_log()<CR>"; desc = "Git Log"; }
      { mode = "n"; key = "<leader>gL"; action = ":lua Snacks.picker.git_log_line()<CR>"; desc = "Git Log Line"; }
      { mode = "n"; key = "<leader>gs"; action = ":lua Snacks.picker.git_status()<CR>"; desc = "Git Status"; }
      { mode = "n"; key = "<leader>gS"; action = ":lua Snacks.picker.git_stash()<CR>"; desc = "Git Stash"; }
      { mode = "n"; key = "<leader>gd"; action = ":lua Snacks.picker.git_diff()<CR>"; desc = "Git Diff (Hunks)"; }
      # gh
      { mode = "n"; key = "<leader>gi"; action = ":lua Snacks.picker.gh_issue()<CR>"; desc = "GitHub Issues (open)"; }
      { mode = "n"; key = "<leader>gI"; action = ":lua Snacks.picker.gh_issue({ state = \"all\" })<CR>"; desc = "GitHub Issues (all)"; }
      { mode = "n"; key = "<leader>gp"; action = ":lua Snacks.picker.gh_pr()<CR>"; desc = "GitHub Pull Requests (open)"; }
      { mode = "n"; key = "<leader>gP"; action = ":lua Snacks.picker.gh_pr({ state = \"all\" })<CR>"; desc = "GitHub Pull Requests (all)"; }
      { mode = "n"; key = "<leader>gt"; action = ":lua Snacks.gitbrowse()<CR>"; desc = "Git Browse"; }
      # Grep
      { mode = "n"; key = "<leader>sb"; action = ":lua Snacks.picker.lines()<CR>"; desc = "Buffer Lines"; }
      { mode = "n"; key = "<leader>sB"; action = ":lua Snacks.picker.grep_buffers()<CR>"; desc = "Grep Open Buffers"; }
      { mode = "n"; key = "<leader>sg"; action = ":lua Snacks.picker.grep()<CR>"; desc = "Grep"; }
      { mode = ["n" "x"]; key = "<leader>sw"; action = ":lua Snacks.picker.grep_word()<CR>"; desc = "Visual selection or word"; }
      # search
      { mode = "n"; key = "<leader>s\""; action = ":lua Snacks.picker.registers()<CR>"; desc = "Registers"; }
      { mode = "n"; key = "<leader>s/"; action = ":lua Snacks.picker.search_history()<CR>"; desc = "Search History"; }
      { mode = "n"; key = "<leader>sa"; action = ":lua Snacks.picker.autocmds()<CR>"; desc = "Autocmds"; }
      { mode = "n"; key = "<leader>sb"; action = ":lua Snacks.picker.lines()<CR>"; desc = "Buffer Lines"; }
      { mode = "n"; key = "<leader>sc"; action = ":lua Snacks.picker.command_history()<CR>"; desc = "Command History"; }
      { mode = "n"; key = "<leader>sC"; action = ":lua Snacks.picker.commands()<CR>"; desc = "Commands"; }
      { mode = "n"; key = "<leader>sd"; action = ":lua Snacks.picker.diagnostics()<CR>"; desc = "Diagnostics"; }
      { mode = "n"; key = "<leader>sD"; action = ":lua Snacks.picker.diagnostics_buffer()<CR>"; desc = "Buffer Diagnostics"; }
      { mode = "n"; key = "<leader>sh"; action = ":lua Snacks.picker.help()<CR>"; desc = "Help Pages"; }
      { mode = "n"; key = "<leader>sH"; action = ":lua Snacks.picker.highlights()<CR>"; desc = "Highlights"; }
      { mode = "n"; key = "<leader>si"; action = ":lua Snacks.picker.icons()<CR>"; desc = "Icons"; }
      { mode = "n"; key = "<leader>sj"; action = ":lua Snacks.picker.jumps()<CR>"; desc = "Jumps"; }
      { mode = "n"; key = "<leader>sk"; action = ":lua Snacks.picker.keymaps()<CR>"; desc = "Keymaps"; }
      { mode = "n"; key = "<leader>sl"; action = ":lua Snacks.picker.loclist()<CR>"; desc = "Location List"; }
      { mode = "n"; key = "<leader>sm"; action = ":lua Snacks.picker.marks()<CR>"; desc = "Marks"; }
      { mode = "n"; key = "<leader>sM"; action = ":lua Snacks.picker.man()<CR>"; desc = "Man Pages"; }
      { mode = "n"; key = "<leader>sp"; action = ":lua Snacks.picker.lazy()<CR>"; desc = "Search for Plugin Spec"; }
      { mode = "n"; key = "<leader>sq"; action = ":lua Snacks.picker.qflist()<CR>"; desc = "Quickfix List"; }
      { mode = "n"; key = "<leader>sR"; action = ":lua Snacks.picker.resume()<CR>"; desc = "Resume"; }
      { mode = "n"; key = "<leader>su"; action = ":lua Snacks.picker.undo()<CR>"; desc = "Undo History"; }
      { mode = "n"; key = "<leader>uC"; action = ":lua Snacks.picker.colorschemes()<CR>"; desc = "Colorschemes"; }
      # LSP
      { mode = "n"; key = "gd"; action = ":lua Snacks.picker.lsp_definitions()<CR>"; desc = "Goto Definition"; }
      { mode = "n"; key = "gD"; action = ":lua Snacks.picker.lsp_declarations()<CR>"; desc = "Goto Declaration"; }
      { mode = "n"; key = "gr"; action = ":lua Snacks.picker.lsp_references()<CR>"; desc = "References"; }
      { mode = "n"; key = "gI"; action = ":lua Snacks.picker.lsp_implementations()<CR>"; desc = "Goto Implementation"; }
      { mode = "n"; key = "gy"; action = ":lua Snacks.picker.lsp_type_definitions()<CR>"; desc = "Goto T[y]pe Definition"; }
      { mode = "n"; key = "gai"; action = ":lua Snacks.picker.lsp_incoming_calls()<CR>"; desc = "C[a]lls Incoming"; }
      { mode = "n"; key = "gao"; action = ":lua Snacks.picker.lsp_outgoing_calls()<CR>"; desc = "C[a]lls Outgoing"; }
      { mode = "n"; key = "<leader>ss"; action = ":lua Snacks.picker.lsp_symbols()<CR>"; desc = "LSP Symbols"; }
      { mode = "n"; key = "<leader>sS"; action = ":lua Snacks.picker.lsp_workspace_symbols()<CR>"; desc = "LSP Workspace Symbols"; }
    ];
  };
}
