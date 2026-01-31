function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- plugin configuration
local plugins = {
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
    { "https://github.com/github/copilot.vim" },
    {
        "https://github.com/folke/which-key.nvim",
        function()
            require("which-key").setup({})
        end,
    },
    { "https://github.com/rafamadriz/friendly-snippets" },
    {
        "https://github.com/saghen/blink.cmp",
        function(plugin)
            if not plugin or not plugin.path then
                return
            end
            local built =
                vim.fn.glob(plugin.path .. "/target/release/*blink*cmp*fuzzy*")
            if built ~= "" then
                return
            end
            vim.notify("Building blink.cmp...", vim.log.levels.INFO)
            local cmd = { "nix", "run", ".#build-plugin" }
            local result = vim.system(cmd, { cwd = plugin.path }):wait()
            if result.code ~= 0 then
                vim.notify("blink.cmp build failed", vim.log.levels.WARN)
            end
            require("blink.cmp").setup({
                keymap = {
                    preset = "super-tab",
                    ["<m-space>"] = { "show" },
                },
                completion = {
                    menu = {
                        auto_show = false,
                        border = "rounded",
                        winhighlight = "Normal:BlinkCmpDoc,"
                            .. "FloatBorder:BlinkCmpDocBorder,"
                            .. "CursorLine:BlinkCmpDocCursorLine,"
                            .. "Search:None",
                    },
                    documentation = {
                        auto_show = true,
                        auto_show_delay_ms = 500,
                        window = { border = "rounded" },
                    },
                },
                appearance = {
                    use_nvim_cmp_as_default = true,
                    nerd_font_variant = "mono",
                },
                sources = {
                    default = { "lsp", "path", "snippets" },
                },
                fuzzy = {
                    implementation = "prefer_rust_with_warning",
                },
            })
        end,
    },
    {
        "https://github.com/neovim/nvim-lspconfig",
        function()
            local cfg = require("lspconfig")
            local servers = {
                {
                    "clangd",
                    {
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
                },
                {
                    "cssls",
                    {
                        cmd = {
                            "nix",
                            "shell",
                            "nixpkgs#vscode-langservers-extracted",
                            "-c",
                            "vscode-css-language-server",
                            "--stdio",
                        },
                    },
                },
                {
                    "html",
                    {
                        cmd = {
                            "nix",
                            "shell",
                            "nixpkgs#vscode-langservers-extracted",
                            "-c",
                            "vscode-html-language-server",
                            "--stdio",
                        },
                    },
                },
                {
                    "jsonls",
                    {
                        cmd = {
                            "nix",
                            "shell",
                            "nixpkgs#vscode-langservers-extracted",
                            "-c",
                            "vscode-json-language-server",
                            "--stdio",
                        },
                    },
                },
                {
                    "nixd",
                    {
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
                },
                {
                    "gopls",
                    {
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
                },
                {
                    "ruff",
                    {
                        cmd = {
                            "uvx",
                            "ruff",
                            "server",
                        },
                    },
                },
                {
                    "ty",
                    {
                        cmd = {
                            "uvx",
                            "ty",
                            "server",
                        },
                    },
                },
                {
                    "lua_ls",
                    {
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
                },
                {
                    "stylua",
                    {
                        cmd = {
                            "nix",
                            "run",
                            "nixpkgs#stylua",
                            "--",
                            "--lsp",
                        },
                    },
                },
                {
                    "rust_analyzer",
                    {
                        cmd = {
                            "nix",
                            "run",
                            "nixpkgs#rust-analyzer",
                        },
                    },
                },
                {
                    "ts_ls",
                    {
                        cmd = {
                            "nix",
                            "run",
                            "nixpkgs#nodePackages.typescript-language-server",
                            "--",
                            "--stdio",
                        },
                    },
                },
                {
                    "tombi",
                    {
                        cmd = {
                            "uvx",
                            "tombi",
                            "lsp",
                        },
                    },
                },
            }

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
                vim.diagnostic.config({ underline = false })
            end

            local capabilities = require("blink.cmp").get_lsp_capabilities({})
            local defaults = {
                on_attach = on_attach,
                capabilities = capabilities,
            }
            for _, val in ipairs(servers) do
                local lsp, opts =
                    val[1], vim.tbl_extend("force", defaults, val[2])
                vim.lsp.config[lsp] = opts
                vim.lsp.enable(lsp)
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
            map("n", "<leader>B", "<cmd>Gitsigns blame<cr>")
            map("n", "<M-b>", "<cmd>Gitsigns toggle_current_line_blame<cr>")
        end,
    },
    { "https://github.com/kshenoy/vim-signature" },
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
                        only_scope = true,
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
            map("n", "<leader>Gb", function()
                snacks.picker.git_branches()
            end, { desc = "Git Branches" })
            map("n", "<leader>Gl", function()
                snacks.picker.git_log()
            end, { desc = "Git Log" })
            map("n", "<leader>GL", function()
                snacks.picker.git_log_line()
            end, { desc = "Git Log Line" })
            map("n", "<leader>Gs", function()
                snacks.picker.git_status()
            end, { desc = "Git Status" })
            map("n", "<leader>GS", function()
                snacks.picker.git_stash()
            end, { desc = "Git Stash" })
            map("n", "<leader>Gd", function()
                snacks.picker.git_diff()
            end, { desc = "Git Diff (Hunks)" })
            map("n", "<leader>Gf", function()
                snacks.picker.git_log_file()
            end, { desc = "Git Log File" })
            map("n", "Q", function()
                snacks.bufdelete()
            end, { desc = "Delete Buffer" })
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
    local opts = plugin[3] or {}
    local name = src:match("([^/]+)$")
    table.insert(specs, {
        src = src,
        name = name,
        version = opts.version,
        data = {
            setup = setup,
        },
    })
    valid[name] = true
end

for _, entry in ipairs(vim.pack.get()) do
    local name = entry.spec.name
    if name and not valid[name] and not entry.active then
        vim.pack.del({ name })
    end
end

vim.pack.add(specs, {
    load = function(plugin)
        local data = plugin.spec.data or {}
        vim.cmd.packadd(plugin.spec.name)
        if data.setup then
            data.setup(plugin)
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
    completeopt = "menuone,noinsert,noselect",
    foldenable = false,
    hidden = true,
    hlsearch = true,
    ignorecase = true,
    joinspaces = false,
    laststatus = 3,
    mouse = "a",
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
    grepprg = "rg --vimgrep -uu --no-messages",

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

map("n", "<Tab>", "<c-w>w")

-- Map the tmux-sent F13 sequence for <c-i> to the default <c-i> behavior
vim.keymap.set("n", "<F13>", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<c-i>", true, false, true),
        "n",
        false
    )
end)

map({ "v", "n" }, "<space>", ":nohl<cr>zz")

map("n", "<leader><leader>", "<cmd>set invpaste paste?<cr>")
map("n", "<leader>n", "<cmd>set invnumber number?<cr>")
map("n", ",w", "<cmd>set invwrap wrap?<cr>")

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
