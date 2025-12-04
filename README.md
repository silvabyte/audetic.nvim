# audetic.nvim

Voice-triggered AI coding assistance for Neovim.

Speak your intent, and let AI make the changes. No typing required.

## How It Works

1. Press `<leader>r` to start recording
2. Speak your command (e.g., "add error handling to this function", "rename this variable to userCount")
3. Press `<leader>r` again to stop
4. Watch as the AI executes your command on the current buffer

## Requirements

- Neovim >= 0.9
- [OpenCode CLI](https://opencode.ai) - AI backend
- [Audetic](https://github.com/silvabyte/audetic) - Voice-to-text engine

## Install

**lazy.nvim**

```lua
return {
  "silvabyte/audetic.nvim",
  event = "VeryLazy",
  opts = {
    model = {
      provider = "anthropic",
      model_id = "claude-sonnet-4-20250514",
    },
    voice = {
      keybind = "<leader>r",  -- Push-to-talk
    },
  },
}
```

Run `:checkhealth audetic` to verify your setup.

## Configuration

```lua
require("audetic").setup({
  -- OpenCode server settings
  server = {
    url = nil,        -- nil = auto-start server
    port = nil,       -- nil = auto-allocate free port
    auto_start = true,
    timeout = 15000,
  },

  -- AI model settings
  model = {
    provider = "anthropic",
    model_id = "claude-sonnet-4-20250514",
  },

  -- Voice settings
  voice = {
    enabled = true,
    keybind = "<leader>r",
  },

  -- UI settings
  ui = {
    window_width = 45,
    success_duration = 2000,  -- ms
    error_duration = 4000,    -- ms
  },
})
```

## Keybindings

| Key | Action |
|-----|--------|
| `<leader>r` | Start/stop voice recording |

## Commands

| Command | Description |
|---------|-------------|
| `:AudeticToggle` | Toggle voice recording |
| `:AudeticCancel` | Cancel active voice operation |
| `:AudeticStatus` | Show current voice state |

## Statusline

Add voice status to your statusline:

```lua
-- lualine example
sections = {
  lualine_x = {
    { require("audetic").statusline },
  },
}
```

Status indicators:
- `[REC]` - Recording
- `[...]` - Processing transcription
- `[AI]` - AI executing command

## Starting Audetic

Before using voice commands, start the Audetic service:

```bash
audetic
```

Audetic runs as a background service on `http://127.0.0.1:3737`.

## Debug Mode

Enable debug logging:

```lua
vim.g.audetic_debug = true
```

View logs with `:messages`.

## License

MIT
