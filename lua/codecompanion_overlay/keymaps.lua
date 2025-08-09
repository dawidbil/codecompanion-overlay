local M = {}

function M.setup()
  local map = vim.keymap.set
  local opts = { noremap = true, silent = true }

  map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", vim.tbl_extend("force", opts, { desc = "CodeCompanion Actions" }))
  map({ "n", "v" }, "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", vim.tbl_extend("force", opts, { desc = "Toggle CodeCompanion Chat" }))
  map({ "n", "v" }, "<leader>ap", "<cmd>CodeCompanionChat perplexity<cr>", vim.tbl_extend("force", opts, { desc = "Open CodeCompanion Perplexity Chat" }))
  map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat copilot<cr>", vim.tbl_extend("force", opts, { desc = "Open CodeCompanion Copilot Chat" }))
  map({ "n", "v" }, "<leader>ao", "<cmd>CodeCompanionChat openai<cr>", vim.tbl_extend("force", opts, { desc = "Open CodeCompanion OpenAI Chat" }))
  map("v", "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", vim.tbl_extend("force", opts, { desc = "Add Selection to CodeCompanion Chat" }))

  vim.cmd [[cab cc CodeCompanion]]
  vim.cmd [[cab ccc CodeCompanionChat]]
end

return M
