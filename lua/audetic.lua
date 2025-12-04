---@class Audetic
---@field config AudeticConfig
---@field server AudeticServer
---@field client AudeticClient
---@field voice AudeticVoice
local M = {}

-- Default configuration
local default_config = {
  server = {
    url = nil, -- nil = auto-start OpenCode server
    port = nil, -- nil = auto-allocate free port
    auto_start = true,
    timeout = 15000,
  },
  model = {
    provider = "anthropic",
    model_id = "claude-haiku-4-5",
  },
  voice = {
    enabled = true,
    keybind = "<leader>r", -- Push-to-talk keybind
  },
  ui = {
    window_width = 45, -- Feedback window width
    success_duration = 2000, -- How long to show success message (ms)
    error_duration = 4000, -- How long to show error message (ms)
  },
}

---Setup audetic.nvim
---@param opts? AudeticConfig User configuration (all fields optional, merged with defaults)
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})

  -- Load modules
  local ok, config_module = pcall(require, "audetic.config")
  if not ok then
    vim.notify("Failed to load audetic.config: " .. config_module, vim.log.levels.ERROR)
    return
  end

  -- Initialize configuration
  config_module.setup(M.config)

  -- Load server module
  local server_ok, server_module = pcall(require, "audetic.server")
  if server_ok then
    M.server = server_module
  end

  -- Load client module
  local client_ok, client_module = pcall(require, "audetic.client")
  if client_ok then
    M.client = client_module
  end

  -- Load voice module
  local voice_ok, voice_module = pcall(require, "audetic.voice")
  if voice_ok then
    M.voice = voice_module
    voice_module.setup()
  end

  -- Auto-start server if configured
  if M.config.server.auto_start and M.server then
    vim.defer_fn(function()
      M.server.start()
    end, 100)
  end

  -- Setup autocommands
  M._setup_autocommands()

  -- Silent initialization (only show in debug mode)
  if vim.g.audetic_debug then
    vim.notify("audetic.nvim initialized", vim.log.levels.INFO)
  end
end

---Setup autocommands
function M._setup_autocommands()
  local group = vim.api.nvim_create_augroup("Audetic", { clear = true })

  -- Cleanup on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      -- Clear pooled sessions
      if M.client and M.client.clear_session_pool then
        M.client.clear_session_pool()
      end

      -- Stop server
      if M.server and M.server.stop then
        M.server.stop()
      end
    end,
  })
end

---Get current configuration
---@return AudeticConfig
function M.get_config()
  return M.config
end

---Check if Audetic is available (returns cached state, non-blocking)
---@return boolean
function M.is_available()
  if not M.server then
    return false
  end
  return M.server.is_running()
end

---Check if Audetic is available with fresh status (async)
---@param callback function Callback(available: boolean)
function M.is_available_async(callback)
  if not M.server then
    callback(false)
    return
  end
  M.server.refresh_status(callback)
end

---Get server status (returns cached state for immediate display)
---@return string
function M.status()
  if not M.server then
    return "Server module not loaded"
  end

  local running = M.server.is_running()
  local status_str = running and "Running" or "Stopped"

  if running then
    local url = M.server.get_url()
    return string.format("OpenCode Server: %s (%s)", status_str, url)
  else
    return string.format("OpenCode Server: %s", status_str)
  end
end

---Toggle voice recording
function M.toggle()
  if M.voice then
    M.voice.toggle()
  else
    vim.notify("Voice module not loaded", vim.log.levels.WARN)
  end
end

---Cancel active voice operation
function M.cancel()
  if M.voice then
    M.voice.cancel()
  end
end

---Get voice state
---@return string state "idle" | "recording" | "processing" | "executing"
function M.get_state()
  if M.voice then
    return M.voice.get_state()
  end
  return "idle"
end

---Check if voice is active
---@return boolean
function M.is_active()
  if M.voice then
    return M.voice.is_active()
  end
  return false
end

---Get statusline component
---@return string
function M.statusline()
  return vim.g.audetic_voice_status or ""
end

return M
