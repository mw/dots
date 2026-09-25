local ns
local annotation
local states = {}

-- Diff buffer against parent of @.
local function render(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local state = states[buf]
    if not state or not state.base then
        return
    end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text = table.concat(lines, "\n")
    -- An empty buffer differs from a file containing one blank line.
    local empty = text == ""
        and vim.api.nvim_buf_call(buf, function()
            return vim.fn.wordcount().bytes == 0
        end)
    if vim.bo[buf].endofline and not empty then
        text = text .. "\n"
    end
    local hunks = vim.text.diff(state.base, text, {
        result_type = "indices",
        algorithm = "histogram",
        indent_heuristic = true,
        ignore_cr_at_eol = true,
    })
    for _, hunk in ipairs(hunks) do
        local removed, start, added = hunk[2], hunk[3], hunk[4]
        for i = 0, added - 1 do
            vim.api.nvim_buf_set_extmark(buf, ns, start + i - 1, 0, {
                number_hl_group = i < removed and "JjChange" or "JjAdd",
                priority = 5,
            })
        end
        if removed > added then
            -- Deleted lines have no buffer row: mark the last replacement,
            -- or the line just before a pure deletion (line 1 at the top).
            local line = added == 0 and start or start + added - 1
            vim.api.nvim_buf_set_extmark(
                buf,
                ns,
                math.max(0, line - 1),
                0,
                { number_hl_group = "JjDelete", priority = 6 }
            )
        end
    end
end

local function refresh(buf)
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" or vim.bo[buf].buftype ~= "" then
        states[buf] = nil
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        return
    end
    local state = { base = states[buf] and states[buf].base }
    states[buf] = state
    local ok = pcall(
        vim.system,
        {
            "jj",
            "--ignore-working-copy",
            "--color=never",
            "--no-pager",
            "file",
            "show",
            "-r",
            "@-",
            "--",
            -- An expression permits an absent file (new in @) as empty output.
            "all() & file:" .. vim.json.encode(path),
        },
        { cwd = vim.fs.dirname(path), text = true },
        vim.schedule_wrap(function(result)
            if states[buf] ~= state or not vim.api.nvim_buf_is_loaded(buf) then
                return
            end
            state.base = result.code == 0 and result.stdout or nil
            render(buf)
        end)
    )
    -- Restored temporary buffers can have a deleted cwd: spawning throws
    -- instead of invoking the callback with a nonzero exit code.
    if not ok then
        state.base = nil
        render(buf)
    end
end

local function highlights()
    for name, link in pairs({
        JjAdd = "DiagnosticOk",
        JjChange = "DiagnosticWarn",
        JjDelete = "DiagnosticError",
    }) do
        vim.api.nvim_set_hl(0, name, { link = link })
    end
end

local M = {}

function M.init(set_tmux_zoom)
    ns = vim.api.nvim_create_namespace("jj_signs")
    local group = vim.api.nvim_create_augroup("jj_signs", { clear = true })
    highlights()
    vim.api.nvim_create_autocmd(
        "ColorScheme",
        { group = group, callback = highlights }
    )
    vim.api.nvim_create_autocmd(
        { "BufEnter", "BufReadPost", "BufWritePost", "BufFilePost" },
        {
            group = group,
            callback = function(args)
                refresh(args.buf)
            end,
        }
    )
    vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        group = group,
        callback = function()
            local buffers = {}
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                buffers[vim.api.nvim_win_get_buf(win)] = true
            end
            for buf in pairs(buffers) do
                refresh(buf)
            end
        end,
    })
    vim.api.nvim_create_autocmd(
        { "TextChanged", "TextChangedI", "TextChangedP" },
        {
            group = group,
            callback = function(args)
                render(args.buf)
            end,
        }
    )
    vim.api.nvim_create_autocmd("BufUnload", {
        group = group,
        callback = function(args)
            states[args.buf] = nil
        end,
    })
    refresh(vim.api.nvim_get_current_buf())

    vim.keymap.set("n", "<leader>B", function()
        if annotation then
            vim.api.nvim_buf_delete(annotation, { force = true })
            return
        end
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(buf)
        if path == "" or vim.bo[buf].buftype ~= "" then
            return
        end
        vim.cmd.update()
        local tick = vim.api.nvim_buf_get_changedtick(buf)
        vim.system(
            {
                "jj",
                "--color=never",
                "--no-pager",
                "file",
                "annotate",
                "-T",
                [[
                    separate(" • ",
                        commit.change_id().short(8),
                        commit.author().name(),
                        commit.author().timestamp().format("%Y-%m-%d"),
                        commit.description().first_line()
                    ) ++ "\n"
                ]],
                "--",
                path,
            },
            { text = true },
            vim.schedule_wrap(function(result)
                if
                    annotation
                    or vim.api.nvim_get_current_win() ~= win
                    or vim.api.nvim_win_get_buf(win) ~= buf
                    or vim.api.nvim_buf_get_changedtick(buf) ~= tick
                    or vim.bo[buf].modified
                then
                    return
                end
                if result.code ~= 0 then
                    vim.notify(vim.trim(result.stderr), vim.log.levels.ERROR)
                    return
                end
                set_tmux_zoom(true)
                local scrollopt = vim.o.scrollopt
                vim.opt.scrollopt = { "ver", "jump" }
                local options = {}
                for name, value in pairs({
                    wrap = false,
                    foldenable = false,
                    scrollbind = true,
                    cursorbind = true,
                }) do
                    options[name] = vim.wo[win][name]
                    vim.wo[win][name] = value
                end
                local view = vim.fn.winsaveview()
                vim.cmd("leftabove 64vnew")
                annotation = vim.api.nvim_get_current_buf()
                vim.api.nvim_buf_set_lines(
                    0,
                    0,
                    -1,
                    false,
                    vim.split(result.stdout, "\n", { trimempty = true })
                )
                for name, value in pairs({
                    buftype = "nofile",
                    bufhidden = "wipe",
                    swapfile = false,
                    modifiable = false,
                    readonly = true,
                    number = false,
                    relativenumber = false,
                    signcolumn = "no",
                }) do
                    vim.opt_local[name] = value
                end
                vim.fn.matchadd("Statement", [[^\S\+]])
                vim.fn.matchadd("String", [[^\S\+ • \zs.\{-}\ze • ]])
                vim.fn.matchadd(
                    "Number",
                    [[ • \zs\d\{4}-\d\{2}-\d\{2}\ze • ]]
                )
                vim.fn.winrestview(view)
                vim.cmd("syncbind")
                vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = true })

                local group = vim.api.nvim_create_augroup(
                    "jj_annotate_split",
                    { clear = true }
                )
                vim.api.nvim_create_autocmd("BufWipeout", {
                    group = group,
                    buffer = annotation,
                    callback = function()
                        annotation = nil
                        vim.api.nvim_del_augroup_by_id(group)
                        vim.o.scrollopt = scrollopt
                        if vim.api.nvim_win_is_valid(win) then
                            for name, value in pairs(options) do
                                vim.wo[win][name] = value
                            end
                        end
                        set_tmux_zoom(false)
                    end,
                })
                -- Close stale annotations rather than let edited lines drift out of sync.
                vim.api.nvim_create_autocmd(
                    { "BufWinLeave", "TextChanged", "TextChangedI" },
                    {
                        group = group,
                        buffer = buf,
                        callback = function(args)
                            if
                                args.event == "BufWinLeave"
                                or vim.api.nvim_buf_get_changedtick(buf)
                                    ~= tick
                            then
                                local target = annotation
                                vim.schedule(function()
                                    if vim.api.nvim_buf_is_valid(target) then
                                        vim.api.nvim_buf_delete(
                                            target,
                                            { force = true }
                                        )
                                    end
                                end)
                            end
                        end,
                    }
                )
            end)
        )
    end, { silent = true, desc = "Toggle jj file annotation" })
end

return M
