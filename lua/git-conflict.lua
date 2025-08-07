local M = {}

-----------------------------------------------------------------------------//
-- REFERENCES:
-----------------------------------------------------------------------------//
-- Detecting the state of a git repository based on files in the .git directory.
-- https://stackoverflow.com/questions/49774200/how-to-tell-if-my-git-repo-is-in-a-conflict
-- git diff commands to git a list of conflicted files
-- https://stackoverflow.com/questions/3065650/whats-the-simplest-way-to-list-conflicted-files-in-git
-- how to show a full path for files in a git diff command
-- https://stackoverflow.com/questions/10459374/making-git-diff-stat-show-full-file-path
-- Advanced merging
-- https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging

-----------------------------------------------------------------------------//
-- Types
-----------------------------------------------------------------------------//

---@alias ConflictSide "'ours'"|"'theirs'"|"'both'"|"'base'"|"'none'"

---@class RangeMark
---@field label integer

--- @class PositionMarks
--- @field current RangeMark
--- @field incoming RangeMark
--- @field ancestor RangeMark?

--- @class Range
--- @field range_start integer
--- @field range_end integer
--- @field content_start integer
--- @field content_end integer

--- @class ConflictPosition
--- @field incoming Range
--- @field current Range
--- @field ancestor Range

--- @class ConflictBufferCache
--- @field positions ConflictPosition[]
--- @field tick integer
--- @field bufnr integer

--- @class GitConflictMappings
--- @field ours string
--- @field theirs string
--- @field none string
--- @field both string
--- @field next string
--- @field prev string

--- @class GitConflictConfig
--- @field default_mappings GitConflictMappings
--- @field default_commands boolean

--- @class GitConflictUserConfig
--- @field default_mappings? GitConflictMappings
--- @field default_commands? boolean

-----------------------------------------------------------------------------//
-- Constants
-----------------------------------------------------------------------------//
local CURRENT_HL = "GitConflictCurrent"
local INCOMING_HL = "GitConflictIncoming"
local ANCESTOR_HL = "GitConflictAncestor"
local CURRENT_LABEL_HL = "GitConflictCurrentLabel"
local INCOMING_LABEL_HL = "GitConflictIncomingLabel"
local ANCESTOR_LABEL_HL = "GitConflictAncestorLabel"
local NAMESPACE = vim.api.nvim_create_namespace("git-conflict")

local conflict_start = "^<<<<<<<"
local conflict_middle = "^======="
local conflict_end = "^>>>>>>>"
local conflict_ancestor = "^|||||||"

--- @type GitConflictConfig
local config = {
    --- @class GitConflictMappings
    default_mappings = {
        ours = "co",
        theirs = "ct",
        none = "c0",
        both = "cb",
        next = "]x",
        prev = "[x",
    },
    default_commands = true,
}

--- A list of buffers that have conflicts in them. This is derived from
--- git using the diff command, and updated at intervals
---@type table<string, ConflictBufferCache>
local visited_buffers = {}

-----------------------------------------------------------------------------//

--https://stackoverflow.com/q/5560248
--https://stackoverflow.com/a/37797380
---Darken a specified hex color
---@param color number
---@param percent number
---@return string
local function shade_color(color, percent)
    --- Returns a table containing the RGB values encoded inside 24 least
    --- significant bits of the number @rgb_24bit
    local function decode_24bit_rgb(rgb_24bit)
        local bit = require("bit")
        return {
            r = bit.band(bit.rshift(rgb_24bit, 16), 255),
            g = bit.band(bit.rshift(rgb_24bit, 8), 255),
            b = bit.band(rgb_24bit, 255),
        }
    end

    local function alter(attr, p)
        return math.floor(attr * (100 + p) / 100)
    end

    local rgb = decode_24bit_rgb(color)
    if not rgb.r or not rgb.g or not rgb.b then
        return "NONE"
    end
    local r, g, b = alter(rgb.r, percent), alter(rgb.g, percent), alter(rgb.b, percent)
    r, g, b = math.min(r, 255), math.min(g, 255), math.min(b, 255)
    return string.format("#%02x%02x%02x", r, g, b)
end

---Set an extmark for each section of the git conflict
---@param bufnr integer
---@param hl string
---@param range_start integer
---@param range_end integer
---@return integer? extmark_id
local function hl_range(bufnr, hl, range_start, range_end)
    if not range_start or not range_end then
        return
    end
    return vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, range_start, 0, {
        hl_group = hl,
        hl_eol = true,
        hl_mode = "combine",
        end_row = range_end,
        priority = vim.hl.priorities.user,
    })
end

---Add highlights and additional data to each section heading of the conflict marker
---These works by covering the underlying text with an extmark that contains the same information
---with some extra detail appended.
---TODO: ideally this could be done by using virtual text at the EOL and highlighting the
---background but this doesn't work and currently this is done by filling the rest of the line with
---empty space and overlaying the line content
---@param bufnr integer
---@param hl_group string
---@param label string
---@param lnum integer
---@return integer extmark id
local function draw_section_label(bufnr, hl_group, label, lnum)
    local remaining_space = vim.api.nvim_win_get_width(0) - vim.api.nvim_strwidth(label)
    return vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, lnum, 0, {
        hl_group = hl_group,
        virt_text = { { label .. string.rep(" ", remaining_space), hl_group } },
        virt_text_pos = "overlay",
        priority = vim.hl.priorities.user,
    })
end

---Highlight each part of a git conflict i.e. the incoming changes vs the current/HEAD changes
---TODO: should extmarks be ephemeral? or is it less expensive to save them and only re-apply
---them when a buffer changes since otherwise we have to reparse the whole buffer constantly
---@param positions ConflictPosition[]
---@param lines string[]
local function highlight_conflicts(bufnr, positions, lines)
    for _, position in ipairs(positions) do
        -- Add one since the index access in lines is 1 based
        local current_label = string.format("%s (Current changes)", lines[position.current.range_start + 1])
        local incoming_label = string.format("%s (Incoming changes)", lines[position.incoming.range_end + 1])

        draw_section_label(bufnr, CURRENT_LABEL_HL, current_label, position.current.range_start)
        hl_range(bufnr, CURRENT_HL, position.current.range_start, position.current.range_end + 1)
        hl_range(bufnr, INCOMING_HL, position.incoming.range_start, position.incoming.range_end + 1)
        draw_section_label(bufnr, INCOMING_LABEL_HL, incoming_label, position.incoming.range_end)

        if not vim.tbl_isempty(position.ancestor) then
            local ancestor_label = string.format("%s (Base changes)", lines[position.ancestor.range_start + 1])
            hl_range(bufnr, ANCESTOR_HL, position.ancestor.range_start + 1, position.ancestor.range_end + 1)
            draw_section_label(bufnr, ANCESTOR_LABEL_HL, ancestor_label, position.ancestor.range_start)
        end
    end
end

---Iterate through the buffer line by line checking there is a matching conflict marker
---when we find a starting mark we collect the position details and add it to a list of positions
---@param lines string[]
---@return ConflictPosition[]
local function detect_conflicts(lines)
    local positions = {}
    local position, has_start, has_middle, has_ancestor = nil, false, false, false
    for index, line in ipairs(lines) do
        local lnum = index - 1
        if line:match(conflict_start) then
            has_start = true
            position = {
                current = { range_start = lnum, content_start = lnum + 1 },
                incoming = {},
                ancestor = {},
            }
        end
        if position and has_start and line:match(conflict_ancestor) then
            has_ancestor = true
            position.ancestor.range_start = lnum
            position.ancestor.content_start = lnum + 1
            position.current.range_end = lnum - 1
            position.current.content_end = lnum - 1
        end
        if position and has_start and line:match(conflict_middle) then
            has_middle = true
            if has_ancestor then
                position.ancestor.content_end = lnum - 1
                position.ancestor.range_end = lnum - 1
            else
                position.current.range_end = lnum - 1
                position.current.content_end = lnum - 1
            end
            position.incoming.range_start = lnum + 1
            position.incoming.content_start = lnum + 1
        end
        if position and has_start and has_middle and line:match(conflict_end) then
            position.incoming.range_end = lnum
            position.incoming.content_end = lnum - 1
            positions[#positions + 1] = position

            position, has_start, has_middle, has_ancestor = nil, false, false, false
        end
    end
    return positions
end

-----------------------------------------------------------------------------//
-- Mappings
-----------------------------------------------------------------------------//

local function setup_buffer_mappings(bufnr)
    local function opts(desc)
        return { silent = true, buffer = bufnr, desc = "Git Conflict: " .. desc, nowait = true }
    end

    vim.keymap.set({ "n", "v" }, config.default_mappings.ours, "<Plug>(git-conflict-ours)", opts("Choose Ours"))
    vim.keymap.set({ "n", "v" }, config.default_mappings.both, "<Plug>(git-conflict-both)", opts("Choose Both"))
    vim.keymap.set({ "n", "v" }, config.default_mappings.none, "<Plug>(git-conflict-none)", opts("Choose None"))
    vim.keymap.set({ "n", "v" }, config.default_mappings.theirs, "<Plug>(git-conflict-theirs)", opts("Choose Theirs"))
    vim.keymap.set({ "v", "v" }, config.default_mappings.ours, "<Plug>(git-conflict-ours)", opts("Choose Ours"))
    vim.keymap.set("n", config.default_mappings.prev, "<Plug>(git-conflict-prev-conflict)", opts("Previous Conflict"))
    vim.keymap.set("n", config.default_mappings.next, "<Plug>(git-conflict-next-conflict)", opts("Next Conflict"))
    vim.b[bufnr].conflict_mappings_set = true
end

local function clear_buffer_mappings(bufnr)
    if not vim.b[bufnr].conflict_mappings_set then
        return
    end
    for _, mapping in pairs(config.default_mappings) do
        vim.keymap.del("n", mapping, { buffer = bufnr })
    end
    vim.b[bufnr].conflict_mappings_set = false
end

---Get the conflict marker positions for a buffer if any and update the buffers state
---@param bufnr integer
local function parse_buffer(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local conflicts = detect_conflicts(lines)

    local name = vim.api.nvim_buf_get_name(bufnr)
    visited_buffers[name] = {
        bufnr = bufnr,
        tick = vim.b[bufnr].changedtick,
        positions = conflicts,
    }

    vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
    if #conflicts > 0 then
        highlight_conflicts(bufnr, conflicts, lines)
        setup_buffer_mappings(bufnr)
    else
        clear_buffer_mappings(bufnr)
    end
end

-----------------------------------------------------------------------------//
-- Highlights
-----------------------------------------------------------------------------//

local function set_highlights()
    vim.api.nvim_set_hl(0, CURRENT_HL, { link = "DiffText", default = true })
    vim.api.nvim_set_hl(0, INCOMING_HL, { link = "DiffAdd", default = true })
    vim.api.nvim_set_hl(0, ANCESTOR_HL, { background = 6824314, default = true })

    local current_hl = vim.api.nvim_get_hl(0, { name = CURRENT_HL, link = false })
    local incoming_hl = vim.api.nvim_get_hl(0, { name = INCOMING_HL, link = false })
    local ancestor_hl = vim.api.nvim_get_hl(0, { name = ANCESTOR_HL, link = false })

    vim.api.nvim_set_hl(0, CURRENT_LABEL_HL, { background = shade_color(current_hl.bg, 60), default = true })
    vim.api.nvim_set_hl(0, INCOMING_LABEL_HL, { background = shade_color(incoming_hl.bg, 60), default = true })
    vim.api.nvim_set_hl(0, ANCESTOR_LABEL_HL, { background = shade_color(ancestor_hl.bg, 60), default = true })
end

---@param direction "'next'"|"'prev'"
local function find(direction)
    local bufname = vim.api.nvim_buf_get_name(0)
    local match = visited_buffers[bufname]
    if not match then
        return
    end

    local line = unpack(vim.api.nvim_win_get_cursor(0))
    local position
    if direction == "next" then
        position = vim.iter(match.positions):find(function(pos)
            return line - 1 < pos.current.range_start
        end) or match.positions[1]
    else
        position = vim.iter(match.positions):rev():find(function(pos)
            return line - 1 > pos.current.range_start
        end) or match.positions[#match.positions]
    end

    if position then
        vim.api.nvim_win_set_cursor(0, { position.current.range_start + 1, 0 })
    end
end

---@param positions ConflictPosition[]
---@param side ConflictSide
local function insert_lines(positions, side)
    local get_lines = vim.api.nvim_buf_get_lines

    for i = #positions, 1, -1 do
        local pos = positions[i]
        local lines = side == "ours" and get_lines(0, pos.current.content_start, pos.current.content_end + 1, false)
            or side == "theirs" and get_lines(0, pos.incoming.content_start, pos.incoming.content_end + 1, false)
            or side == "base" and get_lines(0, pos.ancestor.content_start, pos.ancestor.content_end + 1, false)
            or side == "both" and vim.list_extend(
                get_lines(0, pos.current.content_start, pos.current.content_end + 1, false),
                get_lines(0, pos.incoming.content_start, pos.incoming.content_end + 1, false)
            )
            or side == "none" and {}
            or nil

        if not lines then
            return
        end

        local pos_start = pos.current.range_start < 0 and 0 or pos.current.range_start
        local pos_end = pos.incoming.range_end + 1

        vim.api.nvim_buf_set_lines(0, pos_start, pos_end, false, lines)
        vim.api.nvim_buf_clear_namespace(0, NAMESPACE, pos_start, pos_end)
    end
end

---Select the changes to keep
---@param side ConflictSide
local function choose(side)
    local bufname = vim.api.nvim_buf_get_name(0)
    local match = visited_buffers[bufname]
    if not match then
        return
    end

    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
        local start = vim.api.nvim_buf_get_mark(0, "<")[1]
        local finish = vim.api.nvim_buf_get_mark(0, ">")[1]
        local positions = vim.iter(match.positions)
            :filter(function(pos)
                return pos.current.range_start >= start - 1 and pos.incoming.range_end <= finish + 1
            end)
            :totable()
        insert_lines(positions, side)
    else
        local start = unpack(vim.api.nvim_win_get_cursor(0))
        local positions = vim.iter(match.positions)
            :filter(function(pos)
                return pos.current.range_start <= start - 1 and pos.incoming.range_end >= start - 1
            end)
            :totable()
        insert_lines(positions, side)
    end
    parse_buffer(0)
end

---@param user_config GitConflictUserConfig?
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    set_highlights()

    if config.default_commands then
        vim.api.nvim_create_user_command("GitConflictListQf", function()
            local items = M.conflicts_to_qf_items()
            if #items > 0 then
                vim.fn.setqflist(items, "r")
                vim.cmd.copen()
            end
        end, { nargs = 0 })
    end

    local function opts(desc)
        return { silent = true, desc = "Git Conflict: " .. desc }
    end

    -- stylua: ignore start
    vim.keymap.set({ "n", "v" }, "<Plug>(git-conflict-ours)", function() choose("ours") end, opts("Choose Ours"))
    vim.keymap.set({ "n", "v" }, "<Plug>(git-conflict-both)", function() choose("both") end, opts("Choose Both"))
    vim.keymap.set({ "n", "v" }, "<Plug>(git-conflict-base)", function() choose("base") end, opts("Choose Base"))
    vim.keymap.set({ "n", "v" }, "<Plug>(git-conflict-none)", function() choose("none") end, opts("Choose None"))
    vim.keymap.set({ "n", "v" }, "<Plug>(git-conflict-theirs)", function() choose("theirs") end, opts("Choose Theirs"))
    vim.keymap.set("n", "<Plug>(git-conflict-next-conflict)", function() find("next") end, opts("Next Conflict"))
    vim.keymap.set("n", "<Plug>(git-conflict-prev-conflict)", function() find("prev") end, opts("Previous Conflict"))
    -- stylua: ignore end

    local group = vim.api.nvim_create_augroup("GitConflictCommands", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            set_highlights()
        end,
    })

    vim.api.nvim_create_autocmd({ "VimEnter", "BufRead", "SessionLoadPost", "DirChanged" }, {
        group = group,
        callback = function(args)
            parse_buffer(args.buf)
        end,
    })

    vim.api.nvim_set_decoration_provider(NAMESPACE, {
        on_win = function(_, _, bufnr, _, _)
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if visited_buffers[bufname] and visited_buffers[bufname].tick ~= vim.b[bufnr].changedtick then
                parse_buffer(bufnr)
            end
        end,
    })
end

-- TODO(seb): Should I actually retrieve all the git conflicts for this, and then
-- have them all in the quickfix list? Currently it only works if the files with conflicts
-- already have been opened.
---@return table[]
function M.conflicts_to_qf_items()
    local items = {}
    for filename, visited_buf in pairs(visited_buffers) do
        for _, pos in ipairs(visited_buf.positions) do
            for key, value in pairs(pos) do
                if key == "current" then
                    table.insert(items, {
                        filename = filename,
                        text = string.format("%s change", key, value.range_start + 1),
                        valid = 1,
                        lnum = value.range_start + 1,
                    })
                end
            end
        end
    end

    return items
end

return M
