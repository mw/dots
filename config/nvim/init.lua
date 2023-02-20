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

function update(dst, src)
    local out = {}
    for k, v in pairs(dst) do
        out[k] = v
    end
    for k, v in pairs(src) do
        out[k] = v
    end
    return out
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
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "storm",
                lualine_bold = false,
            })
            vim.cmd('colorscheme tokyonight')
        end
    },
    { 'folke/which-key.nvim', opts = {} },
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
                { 'pylsp', {} },
                { 'lua_ls', {
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
                { 'tsserver', {} }
            }

            local function on_attach(client, bufnr)
                local mappings = {
                    { ',d', vim.lsp.buf.definition },
                    { ',D', vim.lsp.buf.type_definition },
                    { 'K', vim.lsp.buf.hover },
                    { '<c-k>', vim.lsp.buf.signature_help },
                    { 'gi', vim.lsp.buf.implementation },
                    { '<leader>e', vim.diagnostic.open_float },
                    { '<leader>f', vim.lsp.buf.rename },
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

                if client.server_capabilities.document_formatting then
                    vim.cmd([[
                        augroup formatting
                        au!
                        autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting()
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
                local lsp, opts = val[1], update(defaults, val[2])
                cfg[lsp].setup(opts)
            end
        end
    },
    { 'machakann/vim-sandwich' },
    { 'mhinz/vim-signify' },
    { 'kshenoy/vim-signature' },
    {
        'onsails/lspkind-nvim',
        config = function()
            require('lspkind').init({})
        end
    },
    {
        'tpope/vim-fugitive',
        config = function()
            map('n', '<leader>B', ':Git blame<cr>')
        end
    },
    {
        'ludovicchabant/vim-gutentags',
        enable = false,
        config = function()
            local cmd = 'git ls-files -co '
            local exts = {
                'c', 'h', 'cc', 'go', 'py', 'rs', 'ts', 'tsx'
            }
            for _, ext in pairs(exts) do
                cmd = cmd .. string.format('\'*.%s\' ', ext)
            end
            vim.g.gutentags_define_advanced_commands = 1
            vim.g.gutentags_ctags_exclude = { 'vendor/*', 'linux/*' }
            vim.g.gutentags_project_root = { '.git' }
            vim.g.gutentags_file_list_command = {
                markers = {
                    ['.git'] = cmd,
                }
            }
        end
    },
    {
        'vimwiki/vimwiki',
        config = function()
            map('n', '<leader>ww', ':VimwikiIndex<cr>')
            vim.g.vimwiki_list = {
                {
                    path = '~/Private/wiki',
                    syntax = 'markdown',
                    ext = '.md'
                }
            }
        end
    },
    {
        'junegunn/fzf.vim',
        dependencies = {
            'junegunn/fzf',
        },
        config = function()
            local mappings = {
                { ',f', ':Files' },
                { ',b', ':Buffers' },
                { ',g', ':Rg' },
                { '<Leader>g', ':Rg <C-R>=expand("<cword>")<cr>' },
                { ',t', ':Tags' }
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
        build = 'TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                ensure_installed = {
                    "c",
                    "cpp",
                    "css",
                    "lua",
                    "html",
                    "javascript",
                    "markdown",
                    "nix",
                    "python",
                    "rust",
                    "tsx",
                    "typescript",
                },
                highlight = {
                    enable = true
                },
                incremental_selection = {
                  enable = true,
                  keymaps = {
                    init_selection = '<m-o>',
                    node_incremental = '<m-o>',
                    node_decremental = '<m-i>',
                  }
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
                            ['<m-l>'] = '@parameter.inner',
                        },
                        swap_previous = {
                            ['<m-h>'] = '@parameter.inner',
                        }
                    },
                },
            })
        end,
    },
    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/vim-vsnip',
            'hrsh7th/cmp-nvim-lsp',
            'onsails/lspkind-nvim'
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
                    ['<Tab>'] = function(fallback)
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
                    ['<S-Tab>'] = function(fallback)
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
        'kyazdani42/nvim-tree.lua',
        dependencies = {
            'kyazdani42/nvim-web-devicons'
        },
        config = function()
            require('nvim-tree').setup({})
            map('n', '<leader>t', ':NvimTreeToggle<cr>')
        end
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = {
            'kyazdani42/nvim-web-devicons',
        },
        config = function()
            require('lualine').setup({
                options = {
                    theme = 'tokyonight',
                    section_separators = { '', '' },
                    component_separators = { '', '' },
                    icons_enabled = true,
                },
                sections = {
                    lualine_a = { { 'mode', upper = true } },
                    lualine_b = { { 'branch', icon = '' } },
                    lualine_c = { { 'filename', file_status = true } },
                    lualine_x = {},
                    lualine_y = { 'filetype' },
                    lualine_z = { 'location' },
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
opt('o', 'completeopt', 'menuone,noinsert,noselect')
opt('o', 'foldenable', false)
opt('o', 'hidden', true)
opt('o', 'hlsearch', false)
opt('o', 'ignorecase', true)
opt('o', 'joinspaces', false)
opt('o', 'laststatus', 2)
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
opt('w', 'signcolumn', 'yes:1')
opt('w', 'wrap', false)

-- key mappings
map('v', '<space>', 'zz')
map('n', '<space>', 'zz')

map('i', '<s-tab>', 'pumvisible() ? "\\<C-p>" : "\\<tab>"', { expr = true })
map('i', '<tab>', 'pumvisible() ? "\\<C-n>" : "\\<tab>"', { expr = true })

map('n', '<leader><leader>', ':set invpaste paste?<cr>')
map('n', '<leader>n', ':set invnumber number?<cr>')
map('n', ',w', ':set invwrap wrap?<cr>')

map('n', '<c-z>', ':terminal<cr>i')
map('n', '<c-n>', ':bn<cr>')
map('n', '<c-p>', ':bp<cr>')
map('n', 'Q', ':bd!<cr>')
map('n', ',v', ':e ~/.config/nvim/init.lua<cr>')
map('n', ',s', ':luafile ~/.config/nvim/init.lua<cr>')

map('n', ',q', ':cwindow<cr>')
map('n', ',n', ':cnext<cr>')
map('n', ',p', ':cprev<cr>')

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
