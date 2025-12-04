---Configuration management for audetic.nvim
---@class AudeticConfig
---@field server? AudeticServerConfig
---@field model? AudeticModelConfig
---@field voice? AudeticVoiceConfig
---@field ui? AudeticUIConfig

---@class AudeticServerConfig
---@field url? string Server URL (nil = auto-start)
---@field port? number Server port (nil = auto-allocate free port)
---@field auto_start? boolean Auto-start server
---@field timeout? number Request timeout in ms

---@class AudeticModelConfig
---@field provider? string AI provider
---@field model_id? string Model identifier

---@class AudeticVoiceConfig
---@field enabled? boolean Enable voice commands
---@field keybind? string Push-to-talk keybind

---@class AudeticUIConfig
---@field window_width? number Feedback window width
---@field success_duration? number How long to show success message (ms)
---@field error_duration? number How long to show error message (ms)

local M = {}

---@type AudeticConfig
M._config = nil

---Setup configuration
---@param opts? AudeticConfig User configuration (merged with defaults)
function M.setup(opts)
  M._config = opts or {}
end

---Get configuration
---@return AudeticConfig
function M.get()
  if not M._config then
    error("Audetic not configured. Call setup() first.")
  end
  return M._config
end

---Get server configuration
---@return AudeticServerConfig
function M.get_server()
  return M.get().server
end

---Get model configuration
---@return AudeticModelConfig
function M.get_model()
  return M.get().model
end

---Get voice configuration
---@return AudeticVoiceConfig
function M.get_voice()
  return M.get().voice
end

---Get UI configuration
---@return AudeticUIConfig
function M.get_ui()
  return M.get().ui
end

---Update configuration value
---@param path string Dot-separated path (e.g., "voice.enabled")
---@param value any New value
function M.set(path, value)
  local keys = vim.split(path, ".", { plain = true })
  local config = M.get()

  local current = config
  for i = 1, #keys - 1 do
    if current[keys[i]] == nil then
      current[keys[i]] = {}
    end
    current = current[keys[i]]
  end

  current[keys[#keys]] = value
end

---Validate configuration
---@return boolean, string? success, error message
function M.validate()
  local config = M._config
  if not config then
    return false, "No configuration loaded"
  end

  -- Validate server config
  if config.server then
    if config.server.port and (config.server.port < 1024 or config.server.port > 65535) then
      return false, "Invalid server port (must be 1024-65535)"
    end
  end

  return true
end

return M
