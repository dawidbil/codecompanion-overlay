-- Auto-run on startup when the plugin is loaded by your plugin manager.
-- Keeps the user's main config clean.
pcall(function()
  require("codecompanion_overlay").setup()
end)
