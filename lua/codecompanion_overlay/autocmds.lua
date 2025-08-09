local M = {}

local function get_unique_buf_name(base_name)
  local names = {
    "johnny","panam","han","leia","luke","frodo","aragorn","gandalf",
    "yoda","sauron","judy","jacky","bilbo","chewie",
  }
  math.randomseed(os.time())
  local random_name = names[math.random(#names)]
  return string.format('%s "%s"', base_name, random_name)
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionChatModel",
    callback = function(args)
      if not args or not args.data then return end
      local bufnr, model = args.data.bufnr, args.data.model
      if not bufnr or not model then return end

      local old_name = vim.api.nvim_buf_get_name(bufnr)
      local basename = old_name:match('([^/\\]+)$') or old_name
      basename = basename:gsub('%s+"[^"]+"$', '')

      local new_base, count = basename:gsub('%b()', '(' .. model .. ')', 1)
      if count == 0 then
        new_base = string.format('%s (%s)', basename, model)
      end

      vim.api.nvim_buf_set_name(bufnr, get_unique_buf_name(new_base))
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionChatAdapter",
    callback = function(args)
      if not args or not args.data then return end
      local adapter = args.data.adapter
      if not adapter or not adapter.formatted_name or not adapter.model or not adapter.model.name then return end
      if not args.data.bufnr then return end

      local base_name = string.format('%s (%s)', adapter.formatted_name, adapter.model.name)
      vim.api.nvim_buf_set_name(args.data.bufnr, get_unique_buf_name(base_name))
    end,
  })
end

return M
