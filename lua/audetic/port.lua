---Port allocation utilities for audetic.nvim
---Enables multiple Neovim instances to run simultaneously without port conflicts
---@class AudeticPort
local M = {}

---Find an available port by binding to port 0 and letting the OS allocate one
---Uses vim.loop (libuv) which is built into Neovim - no external dependencies
---@return number|nil port The allocated port, or nil on failure
function M.find_free_port()
  local tcp = vim.loop.new_tcp()
  if not tcp then
    return nil
  end

  local ok, _ = tcp:bind("127.0.0.1", 0)
  if not ok then
    tcp:close()
    return nil
  end

  local addr = tcp:getsockname()
  tcp:close()

  if addr and addr.port then
    return addr.port
  end

  return nil
end

---Find a free port with retry logic (synchronous, immediate)
---If the first attempt fails, retry up to max_attempts times
---@param max_attempts? number Maximum attempts (default: 3)
---@return number|nil port The allocated port, or nil on failure
function M.find_free_port_with_retry(max_attempts)
  max_attempts = max_attempts or 3

  for _ = 1, max_attempts do
    local port = M.find_free_port()
    if port then
      return port
    end
    -- No delay - immediate retry since find_free_port is instant
  end

  return nil
end

---Check if a port is available by attempting to bind to it
---@param port number The port to check
---@return boolean available True if port is available
function M.is_port_available(port)
  if not port or port < 1 or port > 65535 then
    return false
  end

  local tcp = vim.loop.new_tcp()
  if not tcp then
    return false
  end

  local ok, _ = tcp:bind("127.0.0.1", port)
  tcp:close()

  return ok == true
end

return M
