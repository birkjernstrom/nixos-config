local getObsidianPath = function(path)
  local home = vim.fn.expand("~")
  local iCloudDrive = home .. "/Library/Mobile Documents/iCloud~md~obsidian"
  -- For some reason "Personal" is repeated twice (nested)
  return iCloudDrive .. "/Documents/Personal" .. path
end

return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  event = {
    "BufReadPre " .. getObsidianPath("/Personal/**.md"),
    "BufNewFile " .. getObsidianPath("/Personal/**.md"),
  },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "Personal",
        path = getObsidianPath("/Personal"),
      },
    },
    templates = {
      subdir = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {},
    },
    daily_notes = {
      folder = "Journal",
      date_format = "%Y-%m-%d",
      template = "Daily Template",
    },
    ui = {
      -- Define how various check-boxes are displayed
      checkboxes = {
        -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "", hl_group = "ObsidianDone" },
        [">"] = { char = "", hl_group = "ObsidianRightArrow" },
        ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        -- Replace the above with this if you don't have a patched font:
        -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
        -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

        -- You can also add more custom ones...
      },
      external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      -- Replace the above with this if you don't have a patched font:
      -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = "ObsidianRefText" },
      highlight_text = { hl_group = "ObsidianHighlightText" },
      tags = { hl_group = "ObsidianTag" },
      hl_groups = {
        -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
        -- ObsidianTodo = { bold = true, fg = "#f78c6c" },
        -- ObsidianDone = { bold = true, fg = "#89ddff" },
        -- ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
        -- ObsidianTilde = { bold = true, fg = "#ff5370" },
        -- ObsidianRefText = { underline = true, fg = "#c792ea" },
        -- ObsidianExtLinkIcon = { fg = "#c792ea" },
        -- ObsidianTag = { italic = true, fg = "#89ddff" },
        -- ObsidianHighlightText = { bg = "#75662e" },
      },
    },
  },
}
