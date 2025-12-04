local M = {}

M.check = function()
  vim.health.start("audetic.nvim")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim >= 0.9")
  else
    vim.health.error("Neovim >= 0.9 required")
  end

  -- Check for opencode CLI
  if vim.fn.executable("opencode") == 1 then
    local version = vim.fn.system("opencode --version 2>/dev/null")
    if vim.v.shell_error ~= 0 then
      version = "unknown"
    end
    vim.health.ok("opencode CLI found: " .. vim.trim(version))
  else
    vim.health.error("opencode CLI not found", {
      "Install from: https://opencode.ai",
    })
  end

  -- Check for Audetic
  if vim.fn.executable("audetic") == 1 then
    vim.health.ok("audetic CLI found")
  else
    vim.health.warn("audetic CLI not found", {
      "Install from: https://github.com/silvabyte/audetic",
      "Voice commands will not work without Audetic running",
    })
  end

  -- Check if Audetic is running
  local audetic_running = false
  local handle = io.popen("curl -s --max-time 1 http://127.0.0.1:3737/status 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result:match("phase") then
      audetic_running = true
    end
  end

  if audetic_running then
    vim.health.ok("Audetic service is running")
  else
    vim.health.info("Audetic service not running (start with: audetic)")
  end

  -- Check for curl
  if vim.fn.executable("curl") == 1 then
    vim.health.ok("curl found")
  else
    vim.health.error("curl not found (required for API requests)")
  end

  -- Check port allocation capability
  local port_ok, port_utils = pcall(require, "audetic.port")
  if port_ok then
    local test_port = port_utils.find_free_port()
    if test_port then
      vim.health.ok("Port allocation working (tested port: " .. test_port .. ")")
    else
      vim.health.error("Port allocation failed - cannot bind to TCP socket")
    end
  else
    vim.health.error("Port module not found")
  end

  -- Check server status (uses cached state, non-blocking)
  local ok, server = pcall(require, "audetic.server")
  if ok and server.is_running and server.is_running() then
    local url = server.get_url and server.get_url() or "unknown"
    vim.health.ok("OpenCode server running at " .. url)
  else
    vim.health.info("OpenCode server not running (starts on first use)")
  end
end

return M
