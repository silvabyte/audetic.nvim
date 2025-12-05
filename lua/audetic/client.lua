---OpenCode REST API client for audetic.nvim
---@class AudeticClient
local M = {}

local config = require("audetic.config")
local utils = require("audetic.utils")
local server = require("audetic.server")

---@type table<string, string> Session pool keyed by project root
local session_pool = {}

---@type number|nil Current job ID for cancellation
local current_job_id = nil

---@type number Request ID for deduplication (incremented on each request)
local request_id = 0

---Cancel any in-flight request
function M.cancel()
  if current_job_id then
    pcall(vim.fn.jobstop, current_job_id)
    current_job_id = nil
  end
  -- Bump request ID to invalidate any pending callbacks
  request_id = request_id + 1
end

---Make HTTP request to OpenCode server
---@param method string HTTP method
---@param path string API path
---@param body? table Request body
---@param callback function Callback(success, result)
---@param opts? table Optional request options (timeout, etc.)
function M.request(method, path, body, callback, opts)
  opts = opts or {}
  local url = server.get_url()
  if not url then
    callback(false, "Server not running")
    return
  end

  local full_url = url .. path

  -- Build curl command with timeout (default 30s, configurable via opts)
  local timeout = opts.timeout or 30
  local cmd = { "curl", "-s", "-X", method, "--max-time", tostring(timeout) }

  -- Always add JSON headers
  table.insert(cmd, "-H")
  table.insert(cmd, "Content-Type: application/json")
  table.insert(cmd, "-H")
  table.insert(cmd, "Accept: application/json")

  if body then
    table.insert(cmd, "-d")
    table.insert(cmd, utils.encode_json(body))
  end

  table.insert(cmd, full_url)

  utils.debug("HTTP request", { method = method, path = path, url = full_url })

  -- Cancel any previous request. Only one request can be in-flight at a time.
  -- This is intentional for voice commands where we want the latest request
  -- to take precedence and avoid race conditions.
  M.cancel()

  -- Capture current request ID for staleness check
  local my_request_id = request_id

  -- Track state for this request
  local stdout_data = {}
  local stderr_data = {}

  local function is_stale()
    return my_request_id ~= request_id
  end

  -- Execute request and track job ID
  current_job_id = vim.fn.jobstart(cmd, {
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
    on_exit = function(job_id, code)
      -- Clear job ID if this is the current job
      if current_job_id == job_id then
        current_job_id = nil
      end

      -- Ignore stale responses (request was cancelled or superseded)
      if is_stale() then
        utils.debug("Ignoring stale response", { job_id = job_id })
        return
      end

      -- Process response on exit to ensure we have all data
      if code ~= 0 then
        local err_msg = #stderr_data > 0 and table.concat(stderr_data, "\n")
          or ("Request failed with code " .. code)
        utils.debug("Request failed", { code = code, stderr = err_msg })
        callback(false, err_msg)
        return
      end

      if #stdout_data == 0 then
        utils.debug("Empty response from server")
        callback(false, "Empty response from server")
        return
      end

      local response = table.concat(stdout_data, "\n")

      -- Check if response looks like HTML (error page)
      if response:match("^%s*<!") or response:match("<html") then
        utils.error("Received HTML instead of JSON")
        callback(false, "Server returned HTML error page")
        return
      end

      local decoded = utils.decode_json(response)

      if decoded then
        utils.debug("API response", { decoded = decoded })
        callback(true, decoded)
      else
        utils.error("Failed to parse JSON response")
        utils.debug("Raw response", { response = response:sub(1, 500) })
        callback(false, "Failed to parse response: " .. response:sub(1, 200))
      end
    end,
  })
end

---Create a new session
---@param callback function Callback(success, session)
function M.create_session(callback)
  M.request("POST", "/session", {}, callback)
end

---Delete session
---@param session_id string Session ID
---@param callback function Callback(success, result)
function M.delete_session(session_id, callback)
  M.request("DELETE", "/session/" .. session_id, nil, callback)
end

---Send message to session
---@param session_id string Session ID
---@param message string Message content
---@param opts? table Optional parameters (timeout, etc.)
---@param callback function Callback(success, result)
function M.send_message(session_id, message, opts, callback)
  -- Handle optional opts parameter
  if type(opts) == "function" then
    callback = opts
    opts = {}
  end
  opts = opts or {}

  -- Get model configuration
  local model_config = config.get_model()

  local body = {
    parts = {
      {
        type = "text",
        text = message,
      },
    },
  }

  -- Add model configuration if provided
  if model_config and model_config.provider and model_config.model_id then
    body.model = {
      providerID = model_config.provider,
      modelID = model_config.model_id,
    }
    utils.debug("Using model", { provider = model_config.provider, model = model_config.model_id })
  end

  -- Pass through request options (e.g., timeout)
  local request_opts = {}
  if opts.timeout then
    request_opts.timeout = opts.timeout
  end

  M.request("POST", "/session/" .. session_id .. "/message", body, callback, request_opts)
end

---Get or create a pooled session for a project
---@param project_root string Project root directory
---@param callback function Callback(success, session_id)
function M._get_pooled_session(project_root, callback)
  -- Check if we have a valid pooled session
  local existing_session = session_pool[project_root]
  if existing_session then
    utils.debug("Reusing pooled session", { id = existing_session })
    callback(true, existing_session)
    return
  end

  -- Create new session and pool it
  M.create_session(function(success, result)
    if not success then
      callback(false, result) -- result is error message on failure
      return
    end

    -- API may return session ID under different keys
    local session_id = result.id or result.sessionID or result.session_id
    if not session_id then
      callback(false, "Session ID not found in response")
      return
    end

    -- Pool the session
    session_pool[project_root] = session_id
    utils.debug("Created and pooled session", { id = session_id, project = project_root })

    callback(true, session_id)
  end)
end

---Clear all pooled sessions
function M.clear_session_pool()
  for _, session_id in pairs(session_pool) do
    M.delete_session(session_id, function() end)
  end
  session_pool = {}
  utils.debug("Cleared session pool")
end

return M
