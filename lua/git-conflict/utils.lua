-----------------------------------------------------------------------------//
-- Utils
-----------------------------------------------------------------------------//
local M = {}

--- Wrapper for [vim.notify]
---@param msg string|string[]
---@param level "error" | "trace" | "debug" | "info" | "warn"
---@param once boolean?
function M.notify(msg, level, once)
    if type(msg) == "table" then
        msg = table.concat(msg, "\n")
    end
    local lvl = vim.log.levels[level:upper()] or vim.log.levels.INFO
    local opts = { title = "Git conflict" }
    if once then
        return vim.notify_once(msg, lvl, opts)
    end
    vim.notify(msg, lvl, opts)
end

---Only call the passed function once every timeout in ms
---@param timeout integer
---@param func function
---@return function
function M.throttle(timeout, func)
    local timer = vim.loop.new_timer()
    local running = false
    return function(...)
        if not running then
            func(...)
            running = true
            timer:start(timeout, 0, function()
                running = false
            end)
        end
    end
end

---@param name string?
---@return vim.api.keyset.get_hl_info
function M.get_hl(name)
    if not name then
        return {}
    end
    return vim.api.nvim_get_hl(0, { name = name })
end

return M
