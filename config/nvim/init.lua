function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- plugin configuration

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "folke/tokyonight.nvim",
        pin = true,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "storm",
                lualine_bold = false,
            })
            vim.cmd("colorscheme tokyonight")
        end,
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        pin = true,
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                lsp_doc_border = true,
            },
            messages = {
                view_search = false,
            },
        },
        dependencies = {
            {
                "MunifTanjim/nui.nvim",
                pin = true,
            },
            {
                "rcarriga/nvim-notify",
                pin = true,
            },
        },
    },
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            {
                "nvim-lua/plenary.nvim",
                pin = true,
            },
            {
                "nvim-treesitter/nvim-treesitter",
                pin = true,
            }
        },
        config = function()
            require("codecompanion").setup({
                adapters = {
                    copilot = function()
                        return require("codecompanion.adapters").extend("copilot", {
                            schema = {
                                model = {
                                    default = "claude-3.5-sonnet"
                                },
                            },
                        })
                    end,
                },
            })
            map("n", "<m-space>", "<cmd>CodeCompanionChat Toggle<cr>",
                { desc = "Code Companion Chat" }
            )
            map("v", "<m-space>", "<cmd>'<,'>CodeCompanion<cr>",
                { desc = "Code Companion" }
            )
        end,
    },
    { "github/copilot.vim" },
    {
        "folke/which-key.nvim",
        pin = true,
        opts = {},
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "saghen/blink.cmp",
            pin = true,
        },
        config = function()
            local cfg = require("lspconfig")
            local servers = {
                {
                    "clangd",
                    {
                        cmd = {
                            "clangd",
                            "--background-index",
                            "--log=verbose",
                        },
                    },
                },
                { "cssls", {} },
                { "html", {} },
                { "jsonls", {} },
                { "rnix", {} },
                {
                    "gopls",
                    {
                        root_dir = cfg.util.root_pattern("Gopkg.toml", "go.mod", ".git"),
                    },
                },
                {
                    "pylsp",
                    {
                        cmd = {
                            "uvx",
                            "--with",
                            "python-lsp-black",
                            "--with",
                            "python-lsp-ruff",
                            "--with",
                            "pydantic",
                            "--with",
                            "pylsp-mypy",
                            "--from",
                            "python-lsp-server",
                            "pylsp",
                        },
                    },
                },
                {
                    "lua_ls",
                    {
                        cmd = { "lua-lsp" },
                        settings = {
                            Lua = {
                                runtime = {
                                    version = "LuaJIT",
                                },
                                diagnostics = {
                                    globals = { "vim" },
                                },
                                workspace = {
                                    library = vim.api.nvim_get_runtime_file("", true),
                                    checkThirdParty = false,
                                },
                                telemetry = {
                                    enable = false,
                                },
                            },
                        },
                    },
                },
                { "rust_analyzer", {} },
                { "ts_ls", {} },
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
                local lsp, opts = val[1], vim.tbl_extend("force", defaults, val[2])
                cfg[lsp].setup(opts)
            end

            vim.fn.sign_define("DiagnosticSignError", {
                text = "",
                texthl = "DiagnosticSignError",
            })
            vim.fn.sign_define("DiagnosticSignWarn", {
                text = "",
                texthl = "DiagnosticSignWarn",
            })
            vim.fn.sign_define("DiagnosticSignInfo", {
                text = "",
                texthl = "DiagnosticSignInfo",
            })
            vim.fn.sign_define("DiagnosticSignHint", {
                text = "",
                texthl = "DiagnosticSignHint",
            })
        end,
    },
    {
        "machakann/vim-sandwich",
        pin = true,
    },
    {
        "lewis6991/gitsigns.nvim",
        pin = true,
        config = function()
            require("gitsigns").setup()
            map("n", "<leader>B", "<cmd>Gitsigns blame<cr>")
        end,
    },
    {
        "kshenoy/vim-signature",
        pin = true,
    },
    {
        'stevearc/quicker.nvim',
        event = "FileType qf",
        pin = true,
        opts = {},
        config = function()
            local quicker = require("quicker")
            map("n", ",q", function()
                quicker.toggle()
            end, { desc = "Toggle quickfix", })
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
                            quicker.expand({ before = 2, after = 2, add_to_existing = true })
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
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter-textobjects",
                pin = true,
            },
        },
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                auto_install = false,
                ensure_installed = {
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
                    "jsonc",
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
                },
                highlight = {
                    enable = true,
                },
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<m-o>",
                        node_incremental = "<m-o>",
                        node_decremental = "<m-i>",
                    },
                },
                indent = {
                    enable = true,
                    disable = { "toml", "gitcommit" },
                },
                textobjects = {
                    move = {
                        enable = true,
                        set_jumps = true,
                    },
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            ["<m-s-j>"] = "@parameter.inner",
                        },
                        swap_previous = {
                            ["<m-s-k>"] = "@parameter.inner",
                        },
                    },
                },
            })
        end,
    },
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            bigfile = { enabled = true },
            explorer = { enabled = true },
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
                            ["<m-a>"] = { "select_all", mode = { "n", "i" } },
                            ["<m-/>"] = { "toggle_preview", mode = { "n", "i" } },
                        }
                    }
                }
            },
            quickfile = { enabled = true },
            words = { enabled = true }
        },
        keys = {
            { ",f", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
            { ",b", function() Snacks.picker.buffers() end, desc = "Buffers" },
            { ",j", function() Snacks.picker.jumps() end, desc = "Jumps" },
            { ",g", function() Snacks.picker.grep() end, desc = "Grep" },
            { ",t", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
            { ",R", function() Snacks.picker.resume() end, desc = "Resume" },
            { ",<cr>", function() Snacks.picker.commands() end, desc = "Commands" },
            { "<leader>t", function() Snacks.explorer() end, desc = "File Explorer" },
            { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
            { "<leader>g", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
            { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
            { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
            { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
            { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
            { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
            { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
            { "<leader>N", function() Snacks.picker.notifications() end, desc = "Notification History" },
            { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
            { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches" },
            { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
            { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
            { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
            { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
            { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
            { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
            { "Q", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
        }
    },
    {
        "saghen/blink.cmp",
        dependencies = {
            "rafamadriz/friendly-snippets",
            pin = true,
        },
        version = "*",
        build = "nix run .#build-plugin",
        pin = true,
        opts = {
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
                per_filetype = {
                    codecompanion = { "codecompanion" },
                }
            },
            fuzzy = {
                implementation = "prefer_rust_with_warning"
            },
        },
        opts_extend = { "sources.default" },
    },
    {
        "rmagatti/auto-session",
        pin = true,
        config = function()
            require("auto-session").setup({
                log_level = "error",
                auto_session_suppress_dirs = { "~/" },
            })
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        pin = true,
        dependencies = {
            {
                "nvim-tree/nvim-web-devicons",
                pin = true,
            },
        },
        config = function()
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
                    lualine_a = { {
                        "mode",
                        fmt = function()
                            return ""
                        end,
                    } },
                    lualine_b = {},
                    lualine_c = {
                        {
                            "filename",
                            path = 1,
                            file_status = true,
                            symbols = { modified = "•", readonly = "" },
                        },
                    },
                    lualine_x = { { "filetype", icon_only = true }, "diagnostics" },
                    lualine_y = { { "branch", icon = "" } },
                    lualine_z = {},
                },
                inactive_sections = {},
            })
        end,
    },
}, {})

-- Set options
local options = {
    -- global options
    backspace = "indent,eol,nostop",
    backup = true,
    backupdir = "/tmp,.",
    cmdheight = 0,
    completeopt = "menuone,noinsert,noselect",
    foldenable = false,
    hidden = true,
    hlsearch = false,
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
map({"v", "n"}, "<space>", "zz")

map("n", "<leader><leader>", "<cmd>set invpaste paste?<cr>")
map("n", "<leader>n", "<cmd>set invnumber number?<cr>")
map("n", ",w", "<cmd>set invwrap wrap?<cr>")

map("n", "<c-z>", "<cmd>terminal<cr>i")
map("n", "<c-n>", "<cmd>bn<cr>")
map("n", "<c-p>", "<cmd>bp<cr>")

map("n", ",v", "<cmd>e ~/.config/nvim/init.lua<cr>")
map("n", ",s", "<cmd>luafile ~/.config/nvim/init.lua<cr>")

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

vim.keymap.set("n", "<tab>", "<cmd>wincmd w<cr>", { desc = "next window" })

vim.keymap.set("n", "<leader>A", function()
    local current_file = vim.fn.expand("%:p")
    if aider_send("/add " .. current_file) then
        vim.notify("Added " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    end
end, { desc = "aider: add buffer" })

vim.keymap.set("n", "<leader>D", function()
    local current_file = vim.fn.expand("%:p")
    if aider_send("/drop " .. current_file) then
        vim.notify("Dropped " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    end
end, { desc = "aider: drop buffer" })

vim.keymap.set("n", "<leader>R", function()
    if aider_send("/reset") then
        vim.notify("Reset", vim.log.levels.INFO)
    end
end, { desc = "aider: reset" })

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

function aider_send(cmd)
    local pane_id = get_tmux_pane("aider")
    if not pane_id then
        vim.notify("aider pane not found", vim.log.levels.ERROR)
        return false
    end
    vim.fn.system({ "tmux", "send-keys", "-t", pane_id, cmd, "Enter" })
    return true
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
