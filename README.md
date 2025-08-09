# codecompanion-overlay

Private overlay plugin that configures and extends [codecompanion.nvim] with:
- custom adapters (Perplexity)
- prompt library entries
- slash commands (Python venv file picker)
- UI niceties (Fidget spinner progress)
- sane defaults, keymaps, and buffer-naming autocommands

## Install (lazy.nvim)

Add this repo to your plugin list and remove your old `codecompanion.lua` file from your main config.

```lua
{
  dir = "~/projects/codecompanion-overlay",  -- or your private git URL
  dependencies = {
    "olimorris/codecompanion.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",
  },
}
```

No extra config needed. The plugin auto-initializes via `plugin/codecompanion-overlay.lua`.

## Structure

```
lua/codecompanion_overlay/
  init.lua               -- entrypoint
  config.lua             -- core CodeCompanion setup (display/strategies/opts)
  keymaps.lua            -- all keymaps
  autocmds.lua           -- buffer naming + model/adapter events
  prompts/commit_changes.lua
  adapters/perplexity.lua
  slash/venv_file.lua
  ui/fidget_spinner.lua
plugin/
  codecompanion-overlay.lua
LICENSE
README.md
```

## License

MIT, same as codecompanion.nvim.
