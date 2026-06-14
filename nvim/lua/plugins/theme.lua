return {
  {
    "kepano/flexoki-neovim",
    name = "flexoki",
    lazy = false, -- Must be loaded during initialization sequence
    priority = 1000, -- Ensure this compiles before other plugins load
    config = function()
      -- Configure background variant explicitly
      vim.o.background = "dark"

      -- Load the default global palette overrides
      vim.cmd([[colorscheme flexoki]])

      -- Optional: Custom UI highlights override to ensure structural consistency
      -- This enforces vertical borders to cleanly match the Waybar and Kitty layouts
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#282726", bg = "NONE" })
      vim.api.nvim_set_hl(0, "LineNr", { fg = "#575653" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#205EA6", bold = true })
    end,
  },
}
