local function venv_file_slash_command(chat)
  local paths = {
    { name = 'Neovim config', path = '~/.config/nvim' },
    { name = 'Neovim plugins', path = '~/.local/share/nvim' },
    { name = 'Prompts', path = '~/.prompts' },
    { name = 'coinfirm_lib', path = '~/coinfirm_lib' },
  }

  local venv_path = os.getenv 'VIRTUAL_ENV'
  if venv_path and venv_path ~= '' then
    table.insert(paths, 1, { name = 'Python Virtual Environment', path = venv_path })
  end

  if #paths == 0 then
    return vim.notify('No paths configured for context_file slash command', vim.log.levels.ERROR)
  end

  local file_slash = require('codecompanion.strategies.chat.slash_commands.file').new {
    Chat = chat,
    config = {
      opts = {
        contains_code = true,
        provider = 'telescope',
      },
    },
  }

  local devicons = require 'nvim-web-devicons'

  local function pick_file_from_dir(selected_dir, SlashCommand)
    local telescope = require 'codecompanion.providers.slash_commands.telescope'
    telescope = telescope.new {
      title = 'Select file from ' .. selected_dir.name,
      output = function(selection)
        return SlashCommand:output(selection)
      end,
    }
    telescope.provider.find_files {
      prompt_title = telescope.title,
      attach_mappings = telescope:display(),
      hidden = true,
      no_ignore = true,
      search_dirs = { selected_dir.path },
      entry_maker = function(entry)
        local Path = require 'plenary.path'
        local root = vim.fn.expand(selected_dir.path)
        local abs = vim.fn.expand(entry)
        local rel = Path.new(abs):make_relative(root)
        local filename = vim.fn.fnamemodify(rel, ':t')
        local ext = vim.fn.fnamemodify(filename, ':e')
        local icon, icon_hl = devicons.get_icon(filename, ext, { default = true })

        local displayer = require('telescope.pickers.entry_display').create {
          separator = ' ',
          items = {
            { width = 2 },
            { remaining = true },
          },
        }

        return {
          value = abs,
          display = function()
            return displayer {
              { icon, icon_hl },
              { rel },
            }
          end,
          ordinal = rel,
          path = abs,
          relative_path = rel,
          icon = icon,
          icon_hl = icon_hl,
        }
      end,
    }
  end

  local SlashCommands = {
    set_provider = function(_, SlashCommand, _)
      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local conf = require('telescope.config').values
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      pickers
        .new({}, {
          prompt_title = 'Select directory',
          finder = finders.new_table {
            results = paths,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.name,
                ordinal = entry.name,
              }
            end,
          },
          sorter = conf.generic_sorter {},
          attach_mappings = function(prompt_bufnr, _)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection and selection.value then
                pick_file_from_dir(selection.value, SlashCommand)
              end
            end)
            return true
          end,
        })
        :find()
    end,
  }

  file_slash:execute(SlashCommands)
end

return venv_file_slash_command
