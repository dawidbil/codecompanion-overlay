local function venv_file_slash_command(chat)
  local venv_dir = os.getenv 'VIRTUAL_ENV'
  if not venv_dir then
    return vim.notify('No venv_dir configured for venv_file slash command', vim.log.levels.ERROR)
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

  local SlashCommands = {
    set_provider = function(_, SlashCommand, providers)
      local telescope = require 'codecompanion.providers.slash_commands.telescope'
      telescope = telescope.new {
        title = 'Select venv file',
        output = function(selection)
          return SlashCommand:output(selection)
        end,
      }
      telescope.provider.find_files {
        prompt_title = telescope.title,
        attach_mappings = telescope:display(),
        hidden = true,
        no_ignore = true,
        search_dirs = { venv_dir },
      }
    end,
  }

  file_slash:execute(SlashCommands)
end

return venv_file_slash_command
