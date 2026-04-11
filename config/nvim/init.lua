function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- maximize tmux pane, useful for viewing diffs
local function set_tmux_zoom(should_zoom)
    if not vim.env.TMUX_PANE then
        return
    end
    local is_zoomed = vim.trim(vim.fn.system({
        "tmux",
        "display-message",
        "-p",
        "-t",
        vim.env.TMUX_PANE,
        "#{window_zoomed_flag}",
    })) == "1"
    if is_zoomed == should_zoom then
        return
    end
    vim.fn.system({
        "tmux",
        "resize-pane",
        "-Z",
        "-t",
        vim.env.TMUX_PANE,
    })
end

-- plugin configuration
local plugins = {
    {
        "nvim.undotree",
        function()
            map("n", "<leader>u", "<cmd>Undotree<cr>")
        end,
    },
    {
        "https://github.com/folke/tokyonight.nvim",
        function()
            require("tokyonight").setup({
                style = "storm",
                lualine_bold = false,
            })
            vim.cmd("colorscheme tokyonight")
        end,
    },
    {
        "https://github.com/OXY2DEV/markview.nvim",
        function()
            map("n", "<m-m>", "<cmd>Markview toggle<cr>")
        end,
    },
    {
        "https://github.com/sindrets/diffview.nvim",
        function()
            local function jump_change(key)
                vim.cmd.normal({
                    args = { ("%d%s"):format(vim.v.count1, key) },
                    bang = true,
                })
            end

            require("diffview").setup({
                hooks = {
                    diff_buf_read = function(bufnr)
                        map("n", "(", function()
                            jump_change("[c")
                        end, {
                            buffer = bufnr,
                            desc = "Previous change",
                        })
                        map("n", ")", function()
                            jump_change("]c")
                        end, {
                            buffer = bufnr,
                            desc = "Next change",
                        })
                    end,
                },
            })
            map("n", "<leader><leader>", function()
                if require("diffview.lib").get_current_view() then
                    set_tmux_zoom(false)
                    vim.cmd("DiffviewClose")
                else
                    set_tmux_zoom(true)
                    vim.cmd("DiffviewOpen -uno")
                    vim.schedule(function()
                        local view = require("diffview.lib").get_current_view()
                        if view and view.class:name() == "DiffView" then
                            view.panel:close()
                        end
                    end)
                end
            end)
        end,
    },
    {
        "https://github.com/folke/which-key.nvim",
        function()
            require("which-key").setup({
                preset = "modern",
                delay = 1000,
            })
        end,
    },
    {
        "https://github.com/neovim/nvim-lspconfig",
        function()
            local cfg = require("lspconfig")
            local completion_enable = vim.lsp.completion.enable

            vim.lsp.completion.enable = function(enable, client_id, bufnr, opts)
                -- Buffer reload callbacks can outlive the client they were
                -- created for when a server is suspended from another nvim.
                if enable and not vim.lsp.get_client_by_id(client_id) then
                    return true
                end
                return completion_enable(enable, client_id, bufnr, opts)
            end

            local servers = {
                clangd = {
                    cmd = {
                        "nix",
                        "shell",
                        "nixpkgs#clang-tools",
                        "-c",
                        "clangd",
                        "--background-index",
                        "--log=verbose",
                    },
                },
                cssls = {
                    cmd = {
                        "nix",
                        "shell",
                        "nixpkgs#vscode-langservers-extracted",
                        "-c",
                        "vscode-css-language-server",
                        "--stdio",
                    },
                },
                html = {
                    cmd = {
                        "nix",
                        "shell",
                        "nixpkgs#vscode-langservers-extracted",
                        "-c",
                        "vscode-html-language-server",
                        "--stdio",
                    },
                },
                jsonls = {
                    cmd = {
                        "nix",
                        "shell",
                        "nixpkgs#vscode-langservers-extracted",
                        "-c",
                        "vscode-json-language-server",
                        "--stdio",
                    },
                },
                nixd = {
                    cmd = {
                        "nix",
                        "run",
                        "nixpkgs#nixd",
                    },
                    formatting = {
                        command = {
                            "nix",
                            "run",
                            "nixpkgs#nixfmt",
                        },
                    },
                },
                gopls = {
                    cmd = {
                        "nix",
                        "run",
                        "nixpkgs#gopls",
                    },
                    root_dir = cfg.util.root_pattern(
                        "Gopkg.toml",
                        "go.mod",
                        ".git"
                    ),
                },
                ruff = {
                    cmd = {
                        "uvx",
                        "ruff",
                        "server",
                    },
                },
                ty = {
                    cmd = {
                        "uvx",
                        "ty",
                        "server",
                    },
                },
                lua_ls = {
                    cmd = {
                        "nix",
                        "run",
                        "nixpkgs#luajitPackages.lua-lsp",
                    },
                    format = {
                        enable = true,
                    },
                    settings = {
                        Lua = {
                            runtime = {
                                version = "LuaJIT",
                            },
                            diagnostics = {
                                globals = { "vim" },
                            },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file(
                                    "",
                                    true
                                ),
                                checkThirdParty = false,
                            },
                            telemetry = {
                                enable = false,
                            },
                        },
                    },
                },
                stylua = {
                    cmd = {
                        "nix",
                        "run",
                        "nixpkgs#stylua",
                        "--",
                        "--lsp",
                    },
                },
                rust_analyzer = {
                    cmd = {
                        "nix",
                        "run",
                        "nixpkgs#rust-analyzer",
                    },
                },
                ts_ls = {
                    cmd = {
                        "nix",
                        "run",
                        "nixpkgs#nodePackages.typescript-language-server",
                        "--",
                        "--stdio",
                    },
                },
                tombi = {
                    cmd = {
                        "uvx",
                        "tombi",
                        "lsp",
                    },
                },
            }

            -- Set up LSP servers
            local function on_attach(client, bufnr)
                local mappings = {
                    { ",d", vim.lsp.buf.definition },
                    { ",D", vim.lsp.buf.type_definition },
                    { "K", vim.lsp.buf.hover },
                    { ",K", vim.lsp.buf.signature_help },
                    { "gi", vim.lsp.buf.implementation },
                    { "<leader>e", vim.diagnostic.open_float },
                    { "<leader>f", vim.lsp.buf.rename },
                    { ",a", vim.lsp.buf.code_action },
                    { ",r", vim.lsp.buf.references },
                    { ",N", vim.diagnostic.goto_next },
                    { ",P", vim.diagnostic.goto_prev },
                    { ",R", "<cmd>lsp restart<cr>" },
                }
                for _, v in ipairs(mappings) do
                    local seq, cmd = v[1], v[2]
                    vim.keymap.set("n", seq, cmd, {
                        noremap = true,
                        silent = true,
                        buffer = bufnr,
                    })
                end

                if client.server_capabilities.documentFormattingProvider then
                    vim.cmd([[
                    augroup formatting
                    au!
                    autocmd BufWritePre <buffer> lua vim.lsp.buf.format({ async=false })
                    augroup END
                ]])
                end
                if client:supports_method("textDocument/completion") then
                    vim.lsp.completion.enable(true, client.id, bufnr, {
                        autotrigger = true,
                    })
                end
                vim.diagnostic.config({ underline = false })
            end

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local defaults = {
                on_attach = on_attach,
                capabilities = capabilities,
            }
            for lsp, opts in pairs(servers) do
                vim.lsp.config[lsp] = vim.tbl_extend("force", defaults, opts)
            end

            -- LSP servers can use a lot of memory. Don't run more than one
            -- instance of an LSP server across different nvim instances. When
            -- attaching LSP servers, indicate to the previous nvim instance
            -- running that server to shut its server down.
            local names = vim.tbl_keys(servers)
            local servername = vim.v.servername
            if servername == "" then
                local ok, value = pcall(vim.fn.serverstart, "lsp")
                if ok then
                    servername = value
                end
            end

            if servername == "" then
                for _, lsp in ipairs(names) do
                    vim.lsp.enable(lsp)
                end
            else
                local pid = vim.fn.getpid()

                local function lease_path(name)
                    return vim.fs.joinpath(
                        vim.uv.os_tmpdir(),
                        "nvim-lsp-" .. name
                    )
                end

                local function read_lease(name)
                    local ok, lines = pcall(vim.fn.readfile, lease_path(name))
                    if not ok or #lines < 2 then
                        return
                    end
                    local owner_pid = tonumber(lines[1])
                    local owner_servername = lines[2]
                    if not owner_pid or owner_servername == "" then
                        return
                    end
                    return owner_pid, owner_servername
                end

                local function claim(name)
                    local owner_pid, owner_servername = read_lease(name)
                    if
                        owner_pid
                        and owner_pid ~= pid
                        and owner_servername ~= servername
                        and vim.uv.kill(owner_pid, 0) == 0
                    then
                        local ok, chan = pcall(
                            vim.fn.sockconnect,
                            "pipe",
                            owner_servername,
                            { rpc = true }
                        )
                        if ok and chan > 0 then
                            pcall(
                                vim.rpcrequest,
                                chan,
                                "nvim_exec_lua",
                                "_G.lease_suspend_lsp(...)",
                                { name }
                            )
                            vim.fn.chanclose(chan)
                        end
                    end
                    vim.fn.writefile(
                        { tostring(pid), servername },
                        lease_path(name)
                    )
                end

                local function enable_all()
                    for _, name in ipairs(names) do
                        if not vim.lsp.is_enabled(name) then
                            vim.lsp.enable(name)
                        end
                    end
                end

                _G.lease_suspend_lsp = function(name)
                    if vim.lsp.is_enabled(name) then
                        vim.lsp.enable(name, false)
                    end
                end

                local group =
                    vim.api.nvim_create_augroup("lsp_focus", { clear = true })
                vim.api.nvim_create_autocmd(
                    { "VimEnter", "VimResume", "FocusGained" },
                    {
                        group = group,
                        callback = function()
                            enable_all()
                        end,
                    }
                )
                vim.api.nvim_create_autocmd("LspAttach", {
                    group = group,
                    callback = function(args)
                        local client =
                            vim.lsp.get_client_by_id(args.data.client_id)
                        if client then
                            claim(client.name)
                        end
                    end,
                })
            end
            vim.diagnostic.config({
                virtual_text = {
                    prefix = "●",
                },
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = "",
                        [vim.diagnostic.severity.WARN] = "",
                        [vim.diagnostic.severity.INFO] = "",
                        [vim.diagnostic.severity.HINT] = "",
                    },
                },
            })
        end,
    },
    { "https://github.com/machakann/vim-sandwich" },
    {
        "https://github.com/lewis6991/gitsigns.nvim",
        function()
            require("gitsigns").setup({
                current_line_blame_opts = {
                    virt_text_pos = "eol",
                },
            })
            vim.api.nvim_create_user_command("GitDiffCommit", function(opts)
                set_tmux_zoom(true)
                vim.cmd({
                    cmd = "DiffviewOpen",
                    args = { opts.args .. "^!" },
                })
            end, {
                nargs = 1,
            })
            map("n", "<leader>B", "<cmd>Gitsigns blame<cr>")
            map("n", "<M-b>", "<cmd>Gitsigns toggle_current_line_blame<cr>")
            map("n", "R", "<cmd>Gitsigns setqflist<cr>")
        end,
    },
    {
        "https://github.com/stevearc/quicker.nvim",
        function()
            local quicker = require("quicker")
            map("n", ",q", function()
                quicker.toggle()
            end, { desc = "Toggle quickfix" })
            map("n", ",n", "<cmd>cnext<cr>")
            map("n", ",p", "<cmd>cprev<cr>")
            vim.keymap.set("n", ",l", function()
                quicker.toggle({ loclist = true })
            end, { desc = "Toggle loclist" })
            quicker.setup({
                keys = {
                    {
                        ">",
                        function()
                            quicker.expand({
                                before = 2,
                                after = 2,
                                add_to_existing = true,
                            })
                        end,
                        desc = "Expand quickfix context",
                    },
                    {
                        "<",
                        function()
                            quicker.collapse()
                        end,
                        desc = "Collapse quickfix context",
                    },
                },
            })
        end,
    },
    {
        "https://github.com/nvim-treesitter/nvim-treesitter",
        function()
            local ts = require("nvim-treesitter")
            local languages = {
                "bash",
                "c",
                "cmake",
                "cpp",
                "css",
                "csv",
                "diff",
                "dockerfile",
                "git_config",
                "git_rebase",
                "gitcommit",
                "gitignore",
                "go",
                "gosum",
                "html",
                "javascript",
                "json",
                "ledger",
                "lua",
                "make",
                "markdown",
                "nix",
                "printf",
                "python",
                "regex",
                "requirements",
                "rust",
                "sql",
                "terraform",
                "tmux",
                "toml",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
            }

            ts.setup({
                install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
            })
            ts.install(languages)

            local group =
                vim.api.nvim_create_augroup("TreesitterSetup", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                callback = function(args)
                    local ok = pcall(vim.treesitter.start, args.buf)
                    if ok then
                        vim.bo[args.buf].indentexpr =
                            "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
            vim.keymap.set({ "n", "x", "o" }, "<A-o>", function()
                if vim.treesitter.get_parser(nil, nil, { error = false }) then
                    require("vim.treesitter._select").select_parent(
                        vim.v.count1
                    )
                else
                    vim.lsp.buf.selection_range(vim.v.count1)
                end
            end, {
                desc = "Select parent treesitter node",
            })
            vim.keymap.set({ "n", "x", "o" }, "<A-i>", function()
                if vim.treesitter.get_parser(nil, nil, { error = false }) then
                    require("vim.treesitter._select").select_child(vim.v.count1)
                else
                    vim.lsp.buf.selection_range(-vim.v.count1)
                end
            end, {
                desc = "Select child treesitter node",
            })
        end,
    },
    {
        "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
        function()
            local tt = require("nvim-treesitter-textobjects")
            tt.setup({
                select = {
                    lookahead = true,
                },
                move = {
                    set_jumps = true,
                },
            })

            local select = require("nvim-treesitter-textobjects.select")
            map({ "x", "o" }, "af", function()
                select.select_textobject("@function.outer", "textobjects")
            end, { desc = "Select function outer" })
            map({ "x", "o" }, "if", function()
                select.select_textobject("@function.inner", "textobjects")
            end, { desc = "Select function inner" })

            local move = require("nvim-treesitter-textobjects.move")
            map({ "n", "x", "o" }, "]f", function()
                move.goto_next_start("@function.outer", "textobjects")
            end, { desc = "Next function start" })
            map({ "n", "x", "o" }, "]c", function()
                move.goto_next_start("@class.outer", "textobjects")
            end, { desc = "Next class start" })
            map({ "n", "x", "o" }, "]F", function()
                move.goto_next_end("@function.outer", "textobjects")
            end, { desc = "Next function end" })
            map({ "n", "x", "o" }, "]C", function()
                move.goto_next_end("@class.outer", "textobjects")
            end, { desc = "Next class end" })
            map({ "n", "x", "o" }, "[f", function()
                move.goto_previous_start("@function.outer", "textobjects")
            end, { desc = "Prev function start" })
            map({ "n", "x", "o" }, "[c", function()
                move.goto_previous_start("@class.outer", "textobjects")
            end, { desc = "Prev class start" })
            map({ "n", "x", "o" }, "[F", function()
                move.goto_previous_end("@function.outer", "textobjects")
            end, { desc = "Prev function end" })
            map({ "n", "x", "o" }, "[C", function()
                move.goto_previous_end("@class.outer", "textobjects")
            end, { desc = "Prev class end" })

            local swap = require("nvim-treesitter-textobjects.swap")
            map("n", "<m-s-j>", function()
                swap.swap_next("@parameter.inner")
            end, { desc = "Swap next parameter" })
            map("n", "<m-s-k>", function()
                swap.swap_previous("@parameter.inner")
            end, { desc = "Swap prev parameter" })
        end,
        { version = "main" },
    },
    {
        "https://github.com/folke/snacks.nvim",
        function()
            local snacks = require("snacks")
            snacks.setup({
                bigfile = { enabled = true },
                explorer = { enabled = true },
                indent = {
                    enabled = false,
                    indent = {
                        char = "┊",
                    },
                    scope = {
                        enabled = true,
                    },
                },
                input = { enabled = true },
                notifier = {
                    enabled = true,
                    timeout = 3000,
                },
                picker = {
                    enabled = true,
                    win = {
                        input = {
                            keys = {
                                ["<m-a>"] = {
                                    "select_all",
                                    mode = { "n", "i" },
                                },
                                ["<m-/>"] = {
                                    "toggle_preview",
                                    mode = { "n", "i" },
                                },
                            },
                        },
                    },
                },
                quickfile = { enabled = true },
                words = { enabled = true },
            })
            map({ "n", "i" }, "<m-i>", function()
                if snacks.indent.enabled then
                    snacks.indent.disable()
                else
                    snacks.indent.enable()
                end
            end, { desc = "Toggle indent guides" })
            map("n", ",f", function()
                snacks.picker.files()
            end, { desc = "Find Files" })
            map("n", ",b", function()
                snacks.picker.buffers({ current = false })
            end, { desc = "Buffers" })
            map("n", ",j", function()
                snacks.picker.jumps()
            end, { desc = "Jumps" })
            map("n", ",g", function()
                snacks.picker.grep()
            end, { desc = "Grep" })
            map("n", ",t", function()
                snacks.picker.lsp_workspace_symbols()
            end, { desc = "LSP Workspace Symbols" })
            map("n", ",R", function()
                snacks.picker.resume()
            end, { desc = "Resume" })
            map("n", ",<cr>", function()
                snacks.picker.commands()
            end, { desc = "Commands" })
            map("n", "<leader>t", function()
                snacks.explorer()
            end, { desc = "File Explorer" })
            map("n", "<leader>:", function()
                snacks.picker.command_history()
            end, { desc = "Command History" })
            vim.keymap.set({ "n", "x" }, "<leader>g", function()
                snacks.picker.grep_word()
            end, {
                desc = "Visual selection or word",
                noremap = true,
                silent = true,
            })
            map("n", "<leader>si", function()
                snacks.picker.icons()
            end, { desc = "Icons" })
            map("n", "<leader>sm", function()
                snacks.picker.marks()
            end, { desc = "Marks" })
            map("n", "<leader>sM", function()
                snacks.picker.man()
            end, { desc = "Man Pages" })
            map("n", "<leader>sl", function()
                snacks.picker.loclist()
            end, { desc = "Location List" })
            map("n", "<leader>sq", function()
                snacks.picker.qflist()
            end, { desc = "Quickfix List" })
            map("n", "<leader>su", function()
                snacks.picker.undo()
            end, { desc = "Undo History" })
            map("n", "<leader>N", function()
                snacks.picker.notifications()
            end, { desc = "Notification History" })
            map("n", "<leader>sh", function()
                snacks.picker.help()
            end, { desc = "Help Pages" })
            map("n", "<leader>Gs", function()
                snacks.picker.git_status()
            end, { desc = "Git Status" })
            map("n", "<leader>GS", function()
                snacks.picker.git_stash()
            end, { desc = "Git Stash" })
            map("n", "<leader>Gd", function()
                snacks.picker.git_diff()
            end, { desc = "Git Diff (Hunks)" })
            map("n", "<leader>W", function()
                snacks.picker.diagnostics()
            end, { desc = "LSP Diagnostics" })
            map("n", "Q", function()
                snacks.bufdelete()
            end, { desc = "Delete Buffer" })
            local function show_git_diff_commit(picker, item)
                picker:close()
                if item and item.commit then
                    vim.schedule(function()
                        vim.cmd.GitDiffCommit(item.commit)
                    end)
                end
            end
            map("n", "<leader>Gb", function()
                snacks.picker.git_branches()
            end, { desc = "Git Branches" })
            map("n", "<leader>Gl", function()
                snacks.picker.git_log({
                    confirm = show_git_diff_commit,
                })
            end, { desc = "Git Log" })
            map("n", "<leader>GL", function()
                snacks.picker.git_log_line({
                    confirm = show_git_diff_commit,
                })
            end, { desc = "Git Log Line" })
            map("n", "<leader>Gf", function()
                snacks.picker.git_log_file({
                    confirm = show_git_diff_commit,
                })
            end, { desc = "Git Log File" })
        end,
    },
    {
        "https://github.com/rmagatti/auto-session",
        function()
            require("auto-session").setup({
                log_level = "error",
                auto_session_suppress_dirs = { "~/" },
            })
        end,
    },
    { "https://github.com/nvim-tree/nvim-web-devicons" },
    {
        "https://github.com/nvim-lualine/lualine.nvim",
        function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                    section_separators = "",
                    component_separators = "",
                    icons_enabled = true,
                    refresh = {
                        statusline = 2000,
                    },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = {
                        {
                            "mode",
                            fmt = function()
                                return ""
                            end,
                        },
                    },
                    lualine_b = {},
                    lualine_c = {
                        {
                            "filename",
                            path = 1,
                            file_status = true,
                            symbols = { modified = "•", readonly = "" },
                        },
                    },
                    lualine_x = {
                        {
                            function()
                                local col = vim.fn.col(".")
                                if col > 80 then
                                    return tostring("󰦪")
                                end
                                return ""
                            end,
                            color = { fg = "#f7768e" },
                        },
                        { "filetype", icon_only = true },
                        "diagnostics",
                    },
                    lualine_y = { { "branch", icon = "" } },
                    lualine_z = {},
                },
                inactive_sections = {},
            })
        end,
    },
}

-- plugin management
local specs = {}
local valid = {}
for _, plugin in ipairs(plugins) do
    local src = plugin[1]
    local setup = plugin[2]
    if src:find("/") then
        local name = src:match("([^/]+)$")
        table.insert(specs, {
            src = src,
            name = name,
            version = plugin[3] and plugin[3].version,
            data = {
                setup = setup,
            },
        })
        valid[name] = true
    else
        vim.cmd.packadd(src)
        if setup then
            setup({
                spec = {
                    name = src,
                },
            })
        end
    end
end

for _, entry in ipairs(vim.pack.get()) do
    local name = entry.spec.name
    if name and not valid[name] and not entry.active then
        vim.pack.del({ name })
    end
end

vim.pack.add(specs, {
    load = function(plugin)
        vim.cmd.packadd(plugin.spec.name)
        local setup = plugin.spec.data and plugin.spec.data.setup
        if setup then
            setup(plugin)
        end
    end,
})

-- set options
local options = {
    -- global options
    backspace = "indent,eol,nostop",
    backup = true,
    backupdir = "/tmp,.",
    cmdheight = 0,
    completeitemalign = "abbr,kind,menu",
    completeopt = "menu,menuone,noinsert,noselect,popup",
    diffopt = {
        "internal",
        "filler",
        "closeoff",
        "context:10",
        "algorithm:histogram",
        "indent-heuristic",
        "inline:char",
    },
    fillchars = "diff: ",
    foldenable = false,
    hidden = true,
    hlsearch = true,
    ignorecase = true,
    joinspaces = false,
    laststatus = 3,
    mouse = "a",
    pumblend = 8,
    pumborder = "rounded",
    pumheight = 12,
    pummaxwidth = 50,
    pumwidth = 20,
    report = 0,
    sessionoptions = "buffers",
    shortmess = "filnxtToOFc",
    showbreak = "→",
    showcmd = false,
    showmatch = true,
    showmode = false,
    smartcase = true,
    smarttab = true,
    splitright = true,
    showtabline = 0,
    termguicolors = true,
    undolevels = 8000,
    undoreload = 30000,
    whichwrap = "h,l,<,>,[,]",
    wildignore = "*.o,*.bak,*.pyc,*.swp,.git,node_modules",
    wildmode = "list:longest",
    winborder = "rounded",
    writebackup = true,

    -- buffer options
    expandtab = true,
    formatoptions = "tcroqnj",
    shiftwidth = 4,
    spelllang = "en_us",
    syntax = "on",
    tabstop = 4,
    textwidth = 80,
    undofile = true,
    grepprg = "rg --vimgrep --no-messages",

    -- window options
    linebreak = true,
    number = true,
    signcolumn = "number",
    wrap = false,
}
for k, v in pairs(options) do
    vim.opt[k] = v
end

-- key mappings
vim.keymap.set({ "n", "x" }, "&", function()
    vim.cmd('normal! "zy' .. (vim.fn.mode() == "n" and "iw" or ""))
    vim.cmd("silent grep! " .. vim.fn.shellescape(vim.fn.getreg("z")))
    vim.cmd("copen")
end)

map("i", "<Tab>", function()
    return vim.fn.pumvisible() == 1 and "<c-n>" or "<Tab>"
end, { expr = true })
map("i", "<s-tab>", function()
    return vim.fn.pumvisible() == 1 and "<c-p>" or "<s-tab>"
end, { expr = true })

-- Map the tmux-sent F13 sequence for <c-i> to the default <c-i> behavior
vim.keymap.set("n", "<F13>", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<c-i>", true, false, true),
        "n",
        false
    )
end)

map({ "v", "n" }, "<space>", ":nohl<cr>zz")

map("n", "<leader>n", "<cmd>silent! set invnumber number?<cr>")
map("n", ",w", "<cmd>silent! set invwrap wrap?<cr>")

map("n", "<c-z>", "<cmd>terminal<cr>i")
map("n", "<c-n>", "<cmd>bn<cr>")
map("n", "<c-p>", "<cmd>bp<cr>")

map("n", ",v", "<cmd>e ~/dots/config/nvim/init.lua<cr>")
map("n", ",s", "<cmd>luafile ~/dots/config/nvim/init.lua<cr>")

map("n", "<leader>ww", "<cmd>e ~/Private/wiki<cr>")

vim.cmd([[
    augroup nonumberterm
    autocmd!
    autocmd TermEnter * setlocal nonumber
    augroup end
]])

-- trailing spaces
vim.cmd("highlight ExtraWhitespace guibg=#403050")
vim.cmd("match ExtraWhitespace /\\s\\+$/")

-- toggle diagnostics
local diagnostics_active = true
map("n", "<m-d>", function()
    diagnostics_active = not diagnostics_active
    if diagnostics_active then
        vim.diagnostic.show()
    else
        vim.diagnostic.hide()
    end
end)

-- tmux-send command
local send_cmd = ""
map("n", ",,", function()
    vim.ui.input({ prompt = "tmux-send ❯ " }, function(result)
        if result == nil then
            return
        end
        send_cmd = result
    end)
    if send_cmd == "" then
        vim.cmd([[
            augroup tmuxsend
            au!
            augroup END
        ]])
    else
        vim.cmd([[
            augroup tmuxsend
            au!
            autocmd BufWritePost * lua tmux_send()
            augroup END
        ]])
        tmux_send()
    end
end)

function get_tmux_pane(pattern)
    local result = vim.fn.system('tmux list-panes -F "#{pane_id} #{pane_tty}"')
    local lines = vim.split(vim.trim(result), "\n")

    local matches = {}
    for _, line in ipairs(lines) do
        local pane_id, tty = line:match("([%%0-9]+)%s+(.*)")
        local ps_result = vim.fn.system("ps -t " .. tty .. " -o command=")
        local cmd = vim.trim(ps_result)
        if cmd:match(pattern) then
            matches[pane_id] = #vim.split(cmd, "\n")
        end
    end

    -- Return the first matching pane_id
    for pane_id, count in pairs(matches) do
        -- Match zsh pane only if count is 1 (not just the parent process)
        if not string.find(pattern, "zsh") or count == 1 then
            return pane_id
        end
    end
    return nil
end

function tmux_send()
    if send_cmd == "" then
        return
    end

    local pane_id = get_tmux_pane("^-?zsh")
    if not pane_id then
        vim.notify("zsh pane not found", vim.log.levels.ERROR)
        return
    end

    vim.fn.system({ "tmux", "send-keys", "-t", pane_id, send_cmd, "Enter" })
end
