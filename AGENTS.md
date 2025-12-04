# AGENTS.md

## Build/Lint Commands

- `make fmt` - Format code with stylua
- `make lint` - Lint code with selene
- `make check` - Run both fmt and lint
- No test framework configured

## Code Style

- **Formatter:** stylua (2-space indent, 100 col width, double quotes, always use parens)
- **Linter:** selene with `lua51+vim` standard
- **Module pattern:** `local M = {} ... return M`
- **Naming:** `snake_case` for functions/variables, `_prefix` for private, `SCREAMING_CASE` for constants
- **Types:** Use LuaDoc annotations (`---@class`, `---@param`, `---@return`, `---@field`)
- **Imports:** Top of file, `local foo = require("audetic.foo")`

## Error Handling

- Use `pcall` for safe requires and risky operations
- Guard clauses with early returns for invalid state
- `vim.notify(msg, vim.log.levels.ERROR)` for user-facing errors

## Async Patterns

- `vim.defer_fn(fn, ms)` for delays, `vim.schedule(fn)` for next tick
- Callback-based async (no coroutines), e.g. `fn(ctx, function(ok, result) end)`

## Architecture

```
lua/
  audetic.lua          -- Main entry point, setup()
  audetic/
    config.lua         -- Configuration management
    utils.lua          -- Utility functions (logging, JSON, etc.)
    port.lua           -- Dynamic port allocation
    server.lua         -- OpenCode server management
    client.lua         -- OpenCode REST API client
    voice.lua          -- Voice recording and command execution
    health.lua         -- :checkhealth integration
```

## Key Components

- **voice.lua** - Core voice functionality: Audetic API integration, recording state machine, feedback UI
- **server.lua** - Manages OpenCode server lifecycle (auto-start, health checks)
- **client.lua** - Session pooling and message sending to OpenCode API
