# audetic.nvim

Voice-triggered AI coding assistance for Neovim.

Speak your intent, and let AI make the changes. No typing required.

## How It Works

1. Press `<leader>r` to start recording (or select text in visual mode first to scope the command)
2. Speak your command (e.g., "add error handling to this function", "rename this variable to userCount")
3. Press `<leader>r` again to stop
4. Watch as the AI executes your command on the current buffer

### Selection-aware context

- **Normal mode**: the whole buffer is sent as context.
- **Visual mode**: the selected range is sent as the primary target, with the rest of the buffer included as surrounding context. The model is instructed to scope changes to the selection.
- **`:'<,'>AudeticToggle`** (or any line range, e.g. `:5,20AudeticToggle`) works the same way as a visual-mode invocation.

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
      model_id = "claude-haiku-4-5",
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
  server = {
    url = nil,           -- nil = auto-start server
    port = nil,          -- nil = auto-allocate free port
    auto_start = true,
    timeout = 15000,     -- request timeout (ms)
  },
  model = {
    provider = "anthropic",
    model_id = "claude-haiku-4-5",
  },
  voice = {
    enabled = true,
    keybind = "<leader>r",
  },
  ui = {
    window_width = 50,      -- feedback window width
    window_max_height = 10, -- feedback window max height
    max_event_log = 50,     -- max messages in chat log
    success_duration = 2000,
    error_duration = 4000,
  },
})
```

All options shown are defaults.

## Keybindings

| Key | Mode | Action |
|-----|------|--------|
| `<leader>r` | Normal | Start/stop voice recording (full-buffer context) |
| `<leader>r` | Visual | Start/stop voice recording, scoped to the current selection |

## Commands

| Command | Description |
|---------|-------------|
| `:AudeticToggle` | Toggle voice recording (full-buffer context) |
| `:'<,'>AudeticToggle` | Toggle voice recording scoped to the selected range |
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
