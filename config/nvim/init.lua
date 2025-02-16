local scopes = { o = vim.o, b = vim.bo, w = vim.wo }

function opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= 'o' then scopes['o'][key] = value end
end

function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
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

require('lazy').setup({
    {
        'folke/tokyonight.nvim',
        pin = true,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "storm",
                lualine_bold = false,
            })
            vim.cmd('colorscheme tokyonight')
        end
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
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                lsp_doc_border = true,
            },
            messages = {
                view_search = false
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
        }
    },
    {
        "robitx/gp.nvim",
        pin = true,
        config = function()
            require("gp").setup({
                providers = {
                    openai = {
                        endpoint = "https://api.openai.com/v1/chat/completions",
                        secret = os.getenv("OPENAI_API_KEY"),
                    },
                    anthropic = {
                        endpoint = "https://api.anthropic.com/v1/messages",
                        secret = os.getenv("ANTHROPIC_API_KEY"),
                    },
                    copilot = {
                        endpoint = "https://api.githubcopilot.com/chat/completions",
                        secret = {
                            "bash",
                            "-c",
                            "cat ~/.config/github-copilot/hosts.json | sed -e 's/.*oauth_token...//;s/\".*//'",
                        },
                    },
                },
                default_chat_agent = "ChatClaude-3-5-Sonnet",
                default_command_agent = "CodeCopilot"
            })
            -- Chat commands
            map("n", "<M-Space><M-Space>", ":GpChatToggle<cr>")
            map("n", "<M-Space><Space>", ":%GpChatNew vsplit<cr>")
            map("v", "<M-Space><Space>", ":'<,'>GpChatPaste vsplit<cr>")
            map("n", "<M-Space>f", ":GpChatFinder<cr>")
            map("n", "<M-Space><cr>", ":GpChatRespond<cr>")
            map("v", "<M-Space><cr>", ":'<,'>GpRewrite<cr>")
            map("n", "<M-Space>d", ":GpChatDelete<cr>")
            map("n", "<M-Space>g", ":GpStop<cr>")
        end,
    },
    { 'github/copilot.vim' },
    {
        'folke/which-key.nvim',
        pin = true,
        opts = {}
    },
    {
        'neovim/nvim-lspconfig',
        config = function()
            local cfg = require('lspconfig')
            local servers = {
                {
                    'clangd', {
                        cmd = {
                            "clangd",
                            "--background-index",
                            "--log=verbose"
                        }
                    }
                },
                { 'cssls', {} },
                { 'html', {} },
                { 'jsonls', {} },
                { 'rnix', {} },
                {
                    'gopls', {
                        root_dir = cfg.util.root_pattern('Gopkg.toml',
                            'go.mod', '.git')
                    }
                },
                {
                    'pylsp', {
                        cmd = {
                            "uvx",
                            "--with", "python-lsp-black",
                            "--with", "python-lsp-ruff",
                            "--with", "pydantic",
                            "--with", "pylsp-mypy",
                            "--from", "python-lsp-server",
                            "pylsp"
                        }
                    }
                },
                { 'lua_ls', {
                    cmd = { 'lua-lsp' },
                    settings = {
                        Lua = {
                            runtime = {
                                version = 'LuaJIT',
                            },
                            diagnostics = {
                                globals = { 'vim' },
                            },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                            telemetry = {
                                enable = false,
                            },
                        }
                    }

                } },
                { 'rust_analyzer', {} },
                { 'ts_ls', {} }
            }

            local function on_attach(client, bufnr)
                local mappings = {
                    { ',d', vim.lsp.buf.definition },
                    { ',D', vim.lsp.buf.type_definition },
                    { 'K', vim.lsp.buf.hover },
                    { ',K', vim.lsp.buf.signature_help },
                    { 'gi', vim.lsp.buf.implementation },
                    { '<leader>e', vim.diagnostic.open_float },
                    { '<leader>f', vim.lsp.buf.rename },
                    { ',a', vim.lsp.buf.code_action },
                    { ',r', vim.lsp.buf.references },
                    { ',N', vim.diagnostic.goto_next },
                    { ',P', vim.diagnostic.goto_prev },
                    { ',q', vim.diagnostic.setloclist },
                }
                for _, v in ipairs(mappings) do
                    local seq, cmd = v[1], v[2]
                    vim.keymap.set('n', seq, cmd, {
                        noremap = true,
                        silent = true,
                        buffer = bufnr
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

            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            local defaults = {
                on_attach = on_attach,
                capabilities = capabilities
            }
            for _, val in ipairs(servers) do
                local lsp, opts = val[1], vim.tbl_extend('force', defaults, val[2])
                cfg[lsp].setup(opts)
            end

            vim.fn.sign_define('DiagnosticSignError', {
                text = '',
                texthl = 'DiagnosticSignError'
            })
            vim.fn.sign_define('DiagnosticSignWarn', {
                text = '',
                texthl = 'DiagnosticSignWarn'
            })
            vim.fn.sign_define('DiagnosticSignInfo', {
                text = '',
                texthl = 'DiagnosticSignInfo'
            })
            vim.fn.sign_define('DiagnosticSignHint', {
                text = '',
                texthl = 'DiagnosticSignHint'
            })
        end
    },
    {
        'machakann/vim-sandwich',
        pin = true
    },
    {
        'lewis6991/gitsigns.nvim',
        pin = true,
        config = function()
            require('gitsigns').setup()
        end
    },
    {
        'kshenoy/vim-signature',
        pin = true
    },
    {
        'onsails/lspkind.nvim',
        pin = true,
        config = function()
            require('lspkind').init({})
        end
    },
    {
        'tpope/vim-fugitive',
        pin = true,
        config = function()
            map('n', '<leader>B', ':Git blame<cr>')
        end
    },
    {
        'vimwiki/vimwiki',
        pin = true,
        config = function()
            map('n', '<leader>ww', ':VimwikiIndex<cr>')
            map('i', '<c-space>', '<plug>VimwikiTableNextCell', { noremap = false })
            vim.g.vimwiki_list = {
                {
                    path = '~/Private/wiki',
                    syntax = 'markdown',
                    ext = '.md'
                }
            }
            vim.cmd('call vimwiki#vars#init()')
        end
    },
    {
        'ibhagwan/fzf-lua',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            local mappings = {
                { ',f', ':FzfLua files' },
                { ',b', ':FzfLua buffers' },
                { ',j', ':FzfLua jumps' },
                { ',g', ':FzfLua live_grep' },
                { '<Leader>g', ':FzfLua grep_cword' },
                { ',t', ':FzfLua treesitter' },
                { ',<CR>', ':FzfLua commands'},
            }
            for _, v in ipairs(mappings) do
                local seq, cmd = v[1], v[2]
                map('n', seq, string.format('%s<cr>', cmd))
            end
        end
    },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
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
                    "html",
                    "javascript",
                    "json",
                    "jsonc",
                    "lua",
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
                        init_selection = '<m-o>',
                        node_incremental = '<m-o>',
                        node_decremental = '<m-i>',
                    }
                },
                indent = {
                    enable = true,
                    disable = {"toml", "gitcommit"}
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
                            ['af'] = '@function.outer',
                            ['if'] = '@function.inner',
                        },
                    },
                    swap = {
                        enable = true,
                        swap_next = {
                            ['<m-s-j>'] = '@parameter.inner',
                        },
                        swap_previous = {
                            ['<m-s-k>'] = '@parameter.inner',
                        }
                    },
                },
            })
        end,
    },
    {
        'drybalka/tree-climber.nvim',
        pin = true,
        config = function()
            local tc = require('tree-climber')
            local opts = { noremap = true, silent = true }
            vim.keymap.set({'n', 'v', 'o'}, '<m-j>', tc.goto_next, opts)
            vim.keymap.set({'n', 'v', 'o'}, '<m-k>', tc.goto_prev, opts)
            vim.keymap.set({'n', 'v', 'o'}, '<m-h>', tc.goto_parent, opts)
        end
    },
    {
        'hrsh7th/nvim-cmp',
        pin = true,
        dependencies = {
            {
                'hrsh7th/vim-vsnip',
                pin = true
            },
            {
                'hrsh7th/cmp-nvim-lsp',
                pin = true
            },
            {
                'onsails/lspkind-nvim',
                pin = true
            }
        },
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                completion = {
                    autocomplete = false
                },
                mapping = {
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<m-Tab>'] = function(fallback)
                        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                        local txt = vim.api.nvim_buf_get_lines(0, line - 1,
                            line, true)[1]
                        local before = txt:sub(col, col)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif before ~= '' and before:match('%s') == nil then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end,
                    ['<m-S-Tab>'] = function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end,
                    ['<CR>'] = cmp.mapping.confirm({ select = true })
                },
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body)
                    end,
                },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'vsnip' }
                }),
                formatting = {
                    fields = { "kind", "abbr" },
                    format = require('lspkind').cmp_format()
                },
            })
        end
    },
    {
        'nvim-tree/nvim-tree.lua',
        pin = true,
        dependencies = {
            'nvim-tree/nvim-web-devicons'
        },
        config = function()
            require('nvim-tree').setup({})
            map('n', '<leader>t', ':NvimTreeToggle<cr>')
        end
    },
    {
        'rmagatti/auto-session',
        pin = true,
        config = function()
            require("auto-session").setup({
                log_level = "error",
                auto_session_suppress_dirs = { "~/" },
            })
        end
    },
    {
        'nvim-lualine/lualine.nvim',
        pin = true,
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            require('lualine').setup({
                options = {
                    theme = 'auto',
                    section_separators = '',
                    component_separators = '',
                    icons_enabled = true,
                    refresh = {
                        statusline = 2000,
                    },
                },
                sections = {
                    lualine_a = {{ 'mode', fmt = function() return '' end }},
                    lualine_b = {},
                    lualine_c = {
                        {
                            'filename', path = 1, file_status = true,
                            symbols = { modified = '•', readonly = '' }
                        }
                    },
                    lualine_x = {{ 'filetype', icon_only = true }, 'diagnostics'},
                    lualine_y = {},
                    lualine_z = {},
                },
                inactive_sections = {}
            })
        end
    }
}, {})

-- global options
opt('o', 'backspace', 'indent,eol,nostop')
opt('o', 'backup', true)
opt('o', 'backupdir', '/tmp,.')
opt('o', 'cmdheight', 0)
opt('o', 'completeopt', 'menuone,noinsert,noselect')
opt('o', 'foldenable', false)
opt('o', 'hidden', true)
opt('o', 'hlsearch', false)
opt('o', 'ignorecase', true)
opt('o', 'joinspaces', false)
opt('o', 'laststatus', 3)
opt('o', 'mouse', 'a')
opt('o', 'report', 0)
opt('o', 'sessionoptions', 'buffers')
opt('o', 'shortmess', 'filnxtToOFc')
opt('o', 'showbreak', '→')
opt('o', 'showcmd', false)
opt('o', 'showmatch', true)
opt('o', 'showmode', false)
opt('o', 'smartcase', true)
opt('o', 'smarttab', true)
opt('o', 'splitright', true)
opt('o', 'termguicolors', true)
opt('o', 'undolevels', 8000)
opt('o', 'undoreload', 30000)
opt('o', 'whichwrap', 'h,l,<,>,[,]')
opt('o', 'wildignore', '*.o,*.bak,*.pyc,*.swp,.git,node_modules')
opt('o', 'wildmode', 'list:longest')
opt('o', 'writebackup', true)

-- buffer options
opt('b', 'expandtab', true)
opt('b', 'formatoptions', 'tcroqnj')
opt('b', 'shiftwidth', 4)
opt('b', 'spelllang', 'en_us')
opt('b', 'syntax', 'on')
opt('b', 'tabstop', 4)
opt('b', 'textwidth', 80)
opt('b', 'undofile', true)

-- window options
opt('w', 'linebreak', true)
opt('w', 'number', true)
opt('w', 'signcolumn', 'number')
opt('w', 'wrap', false)

-- key mappings
map('v', '<space>', 'zz')
map('n', '<space>', 'zz')

map('i', '<m-s-tab>', 'pumvisible() ? "\\<C-p>" : "\\<tab>"', { expr = true })
map('i', '<m-tab>', 'pumvisible() ? "\\<C-n>" : "\\<tab>"', { expr = true })

map('n', '<leader><leader>', ':set invpaste paste?<cr>')
map('n', '<leader>n', ':set invnumber number?<cr>')
map('n', ',w', ':set invwrap wrap?<cr>')

map('n', '<c-z>', ':terminal<cr>i')
map('n', '<c-n>', ':bn<cr>')
map('n', '<c-p>', ':bp<cr>')

map('n', ',v', ':e ~/.config/nvim/init.lua<cr>')
map('n', ',s', ':luafile ~/.config/nvim/init.lua<cr>')

map('n', ',q', ':cwindow<cr>')
map('n', ',n', ':cnext<cr>')
map('n', ',p', ':cprev<cr>')

vim.keymap.set('n', 'Q', function()
    for _, win in pairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 then
            vim.cmd('cclose')
        end
    end
    vim.cmd('bd!')
end, { noremap = true, silent = true })

-- autocommands
vim.cmd('autocmd TermEnter * setlocal nonumber')

-- trailing spaces
vim.cmd('highlight ExtraWhitespace guibg=#403050')
vim.cmd('match ExtraWhitespace /\\s\\+$/')

-- toggle diagnostics
local diagnostics_active = true
vim.keymap.set('n', '<m-d>', function()
    diagnostics_active = not diagnostics_active
    if diagnostics_active then
        vim.diagnostic.show()
    else
        vim.diagnostic.hide()
    end
end)

-- tmux-send command
local send_cmd = ''
vim.keymap.set('n', ',,', function()
    vim.ui.input({ prompt = 'tmux-send ❯ ' }, function(result)
        if result == nil then
            return
        end
        send_cmd = result
    end)
    if send_cmd == '' then
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

function tmux_send()
    if send_cmd == '' then
        return
    end
    vim.fn.system({ 'tmux', 'send-keys', '-t', '{last}', 'C-c' })
    vim.fn.system({ 'tmux', 'send-keys', '-t', '{last}', send_cmd, 'Enter' })
end
