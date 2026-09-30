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

--- @class Range
--- @field range_start integer
--- @field range_end integer
--- @field content_start integer
--- @field content_end integer

--- @class ConflictPosition
--- @field incoming Range
--- @field current Range
--- @field ancestor Range

--- @class GitConflictMappings
--- @field ours string
--- @field theirs string
--- @field none string
--- @field both string
--- @field next string
--- @field prev string

--- @class GitConflictConfig
--- @field default_mappings GitConflictMappings|false

--- @class GitConflictUserConfig
--- @field default_mappings? GitConflictMappings|false

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
}

local mappings = {
    { key = "ours", modes = { "n", "v" }, plug = "<Plug>(git-conflict-ours)" },
    { key = "theirs", modes = { "n", "v" }, plug = "<Plug>(git-conflict-theirs)" },
    { key = "both", modes = { "n", "v" }, plug = "<Plug>(git-conflict-both)" },
    { key = "none", modes = { "n", "v" }, plug = "<Plug>(git-conflict-none)" },
    { key = "prev", modes = { "n" }, plug = "<Plug>(git-conflict-prev-conflict)" },
    { key = "next", modes = { "n" }, plug = "<Plug>(git-conflict-next-conflict)" },
}

-----------------------------------------------------------------------------//

--https://stackoverflow.com/q/5560248
--https://stackoverflow.com/a/37797380
---Darken a specified hex color
---@param color number
---@param percent number
---@return string
local function shade_color(color, percent)
    if not color then
        return "NONE"
    end
    local function channel(shift)
        local value = math.floor(color / 2 ^ shift) % 256
        return math.min(math.floor(value * (100 + percent) / 100), 255)
    end
    return string.format("#%02x%02x%02x", channel(16), channel(8), channel(0))
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
    local position, section
    for index, line in ipairs(lines) do
        local lnum = index - 1
        if line:match(conflict_start) then
            position = { current = { range_start = lnum, content_start = lnum + 1 }, incoming = {}, ancestor = {} }
            section = position.current
        elseif position and section == position.current and line:match(conflict_ancestor) then
            section.range_end, section.content_end = lnum - 1, lnum - 1
            position.ancestor = { range_start = lnum, content_start = lnum + 1 }
            section = position.ancestor
        elseif position and section ~= position.incoming and line:match(conflict_middle) then
            section.range_end, section.content_end = lnum - 1, lnum - 1
            position.incoming = { range_start = lnum + 1, content_start = lnum + 1 }
            section = position.incoming
        elseif position and section == position.incoming and line:match(conflict_end) then
            position.incoming.range_end = lnum
            position.incoming.content_end = lnum - 1
            positions[#positions + 1] = position

            position, section = nil, nil
        end
    end
    return positions
end

-----------------------------------------------------------------------------//
-- Mappings
-----------------------------------------------------------------------------//

local function setup_buffer_mappings(buf)
    if not config.default_mappings or vim.b[buf].conflict_mappings_set then
        return
    end
    for _, m in ipairs(mappings) do
        vim.keymap.set(m.modes, config.default_mappings[m.key], m.plug, { silent = true, buffer = buf, nowait = true })
    end
    vim.b[buf].conflict_mappings_set = true
end

local function clear_buffer_mappings(bufnr)
    if not vim.b[bufnr].conflict_mappings_set then
        return
    end
    for _, mapping in ipairs(mappings) do
        for _, mode in ipairs(mapping.modes) do
            vim.keymap.del(mode, config.default_mappings[mapping.key], { buffer = bufnr })
        end
    end
    vim.b[bufnr].conflict_mappings_set = false
end

---Get the conflict marker positions for a buffer if any and update the buffers state
---@param bufnr integer
local function parse_buffer(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local conflicts = detect_conflicts(lines)

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
    local conflicts = detect_conflicts(vim.api.nvim_buf_get_lines(0, 0, -1, false))

    local line = unpack(vim.api.nvim_win_get_cursor(0))
    local position
    if direction == "next" then
        position = vim.iter(conflicts):find(function(pos)
            return line - 1 < pos.current.range_start
        end) or conflicts[1]
    else
        position = vim.iter(conflicts):rev():find(function(pos)
            return line - 1 > pos.current.range_start
        end) or conflicts[#conflicts]
    end

    if position then
        vim.api.nvim_win_set_cursor(0, { position.current.range_start + 1, 0 })
    end
end

---@param positions ConflictPosition[]
---@param side ConflictSide
local function insert_lines(positions, side)
    local get_lines = vim.api.nvim_buf_get_lines
    local sections = { ours = "current", theirs = "incoming", base = "ancestor" }

    local function content(section)
        return get_lines(0, section.content_start, section.content_end + 1, false)
    end

    for i = #positions, 1, -1 do
        local pos = positions[i]
        if side == "base" and not pos.ancestor.content_start then
            return
        end
        local lines = sections[side] and content(pos[sections[side]])
            or side == "both" and vim.list_extend(content(pos.current), content(pos.incoming))
            or side == "none" and {}
            or nil

        if not lines then
            return
        end

        local pos_start = pos.current.range_start
        local pos_end = pos.incoming.range_end + 1

        vim.api.nvim_buf_set_lines(0, pos_start, pos_end, false, lines)
    end
end

---Select the changes to keep
---@param side ConflictSide
local function choose(side)
    local conflicts = detect_conflicts(vim.api.nvim_buf_get_lines(0, 0, -1, false))

    local mode = vim.fn.mode()
    local start = vim.api.nvim_win_get_cursor(0)[1] - 1
    local finish = start
    local visual = mode == "v" or mode == "V" or mode == "\22"
    if visual then
        local anchor = vim.fn.getpos("v")[2] - 1
        start, finish = math.min(start, anchor), math.max(start, anchor)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    end
    local positions = vim.iter(conflicts)
        :filter(function(pos)
            if visual then
                return pos.current.range_start >= start and pos.incoming.range_end <= finish
            end
            return pos.current.range_start <= start and pos.incoming.range_end >= start
        end)
        :totable()
    insert_lines(positions, side)
    parse_buffer(0)
end

local function create_commands()
    local arguments = { "qf" }
    vim.api.nvim_create_user_command("GitConflict", function(c_opts)
        local args = c_opts.fargs
        if args[1] == "qf" then
            local items = M.conflicts_to_qf_items()
            if #items > 0 then
                vim.fn.setqflist(items, "r")
                vim.cmd.copen()
            end
        else
            vim.notify(string.format("Invalid command: %s", args[1]), vim.log.levels.ERROR, { title = "Git Conflict" })
        end
    end, {

        complete = function()
            return arguments
        end,
        nargs = "?",
        bar = true,
    })
end

---@param user_config GitConflictUserConfig?
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    set_highlights()
    create_commands()

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
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = function(args)
            parse_buffer(args.buf)
        end,
    })
end

---@return table[]
function M.conflicts_to_qf_items()
    local root = vim.fs.root(0, ".git")
    local res = vim.system({ "git", "diff", "--name-only", "--diff-filter=U" }, { cwd = root }):wait()
    local files = vim.split(res.stdout, "\n", { trimempty = true })

    local items = {}

    for _, filename in ipairs(files) do
        local full_path = vim.fs.joinpath(root, filename)
        local bufnr = vim.fn.bufadd(full_path)
        if vim.fn.bufloaded(bufnr) == 0 then
            vim.fn.bufload(bufnr)
        end

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local conflicts = detect_conflicts(lines)
        for _, pos in ipairs(conflicts) do
            items[#items + 1] = {
                filename = full_path,
                text = "current change",
                valid = 1,
                lnum = pos.current.range_start + 1,
            }
        end
    end

    return items
end

return M
