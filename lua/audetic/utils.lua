---Utility functions for audetic.nvim
local M = {}

---Check if a command exists
---@param cmd string Command name
---@return boolean
function M.has_command(cmd)
  return vim.fn.executable(cmd) == 1
end

---Get project root directory
---@param path? string Starting path (default: current buffer)
---@return string? root Root directory or nil
function M.get_project_root(path)
  path = path or vim.api.nvim_buf_get_name(0)

  -- If empty buffer, use cwd
  if path == "" then
    return vim.fn.getcwd()
  end

  -- Search for markers
  local markers = { ".git", "package.json", "go.mod", "Cargo.toml", ".opencode" }

  local root = vim.fs.find(markers, {
    path = path,
    upward = true,
  })[1]

  if root then
    return vim.fs.dirname(root)
  end

  -- Fallback to cwd
  return vim.fn.getcwd()
end

---Convert table to JSON string
---@param t table Table to encode
---@return string json
function M.encode_json(t)
  -- If table is empty, ensure it encodes as {} not []
  if next(t) == nil then
    return "{}"
  end

  -- Use vim.json.encode if available (Neovim 0.10+), otherwise fallback
  if vim.json and vim.json.encode then
    return vim.json.encode(t)
  else
    return vim.fn.json_encode(t)
  end
end

---Parse JSON string to table
---@param str string JSON string
---@return table? decoded
function M.decode_json(str)
  local ok, result = pcall(vim.fn.json_decode, str)
  if ok then
    return result
  end
  return nil
end

---Log debug message (completely silent, only visible in :messages)
---@param msg string Message
---@param data? table Optional data to log
function M.debug(msg, data)
  if vim.g.audetic_debug then
    local log_msg = "[Audetic] " .. msg
    if data then
      -- Truncate large data to prevent message overflow
      local data_str = vim.inspect(data)
      if #data_str > 500 then
        data_str = data_str:sub(1, 500) .. "... (truncated)"
      end
      log_msg = log_msg .. " " .. data_str
    end
    -- Silently add to message history using execute (no display, no prompt)
    vim.schedule(function()
      pcall(vim.fn.execute, string.format("echomsg %s", vim.fn.string(log_msg)), "silent")
    end)
  end
end

---Log info message (non-blocking)
---@param msg string Message
function M.info(msg)
  -- Use echo instead of notify to avoid blocking
  vim.api.nvim_echo({ { "[Audetic] " .. msg, "Normal" } }, false, {})
end

---Log warning message (non-blocking)
---@param msg string Message
function M.warn(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { "[Audetic] " .. msg, "WarningMsg" } }, true, {})
  end)
end

---Log error message (non-blocking)
---@param msg string Message
function M.error(msg)
  vim.schedule(function()
    vim.api.nvim_echo({ { "[Audetic] " .. msg, "ErrorMsg" } }, true, {})
  end)
end

---Execute curl command asynchronously
---@param args string[] Curl arguments (excluding 'curl' itself)
---@param callback function Callback(success: boolean, output: string)
---@param opts? {timeout?: number} Options (default timeout: 5s)
function M.async_curl(args, callback, opts)
  opts = opts or {}
  local timeout = opts.timeout or 5

  -- Build command with curl and timeout
  local cmd = { "curl", "-s", "--max-time", tostring(timeout) }
  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end

  local stdout_data = {}
  local stderr_data = {}

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_data, line)
          end
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          local err_msg = #stderr_data > 0 and table.concat(stderr_data, "\n")
            or ("curl failed with code " .. code)
          callback(false, err_msg)
        else
          local output = table.concat(stdout_data, "\n")
          callback(true, output)
        end
      end)
    end,
  })

  -- Handle jobstart failures: -1 = command not found, 0 = invalid args
  if job_id <= 0 then
    vim.schedule(function()
      callback(false, "Failed to start curl process (job_id: " .. job_id .. ")")
    end)
  end
end

return M
