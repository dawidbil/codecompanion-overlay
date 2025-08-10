local M = {}

function M.setup()
  require('codecompanion_overlay.ui.fidget_spinner').init()
  require('codecompanion_overlay.keymaps').setup()
  require('codecompanion_overlay.autocmds').setup()

  require('codecompanion_overlay.config').setup()
end

return M
