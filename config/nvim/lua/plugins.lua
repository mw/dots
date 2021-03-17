vim.cmd('packadd packer.nvim')

local M = {}
local packer = require('packer')

function lspconfig()
    local cfg = require('lspconfig')
    local completion = require('completion')
    local util = require('util')
    local servers = {
        {
            'clangd', {
                cmd = {"clangd", "--background-index", "--log=verbose"}
            }
        },
        {'cssls', {}},
        {'html', {}},
        {'jsonls', {}},
        {
            'gopls', {
                root_dir = cfg.util.root_pattern('Gopkg.toml', 'go.mod', '.git')
            }
        },
        {'pyls', {}},
        {'rust_analyzer', {}},
        {'tsserver', {}}
    }

    vim.lsp.set_log_level("trace")

    local function on_attach(client, bufnr)
        local function map(...)
            vim.api.nvim_buf_set_keymap(bufnr, ...)
        end
        local host = require('util').host
        local opts = {noremap=true, silent=true}
        map('n', ',d', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        map('n', ',D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        map('n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        map('n', '<leader>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
        map('n', '<leader>f', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        map('n', ',r', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        map('n', ',N', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
        map('n', ',P', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        map('n', ',q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

        vim.cmd('highlight LspDiagnosticsDefaultError guifg=#606060')

        if (not host.disable_lsp_fmt[client.name]) and
            client.resolved_capabilities.document_formatting then
            vim.cmd([[
                autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting()
            ]])
        end
        completion.on_attach(client, bufnr)
    end
    local defaults = {on_attach = on_attach}
    for _, val in ipairs(servers) do
        local lsp, opts = val[1], util.update(defaults, val[2])
        cfg[lsp].setup(opts)
    end
end

function M.init()
    local util = require('util')
    util.map('n', '<leader>pc', ':PackerCompile<cr>')
    util.map('n', '<leader>ps', ':PackerSync<cr>')

    packer.startup(function(use)
        use {'wbthomason/packer.nvim', opt = true}
        use {
            'junegunn/seoul256.vim',
            config = function()
                vim.g.seoul256_background = 236
                vim.cmd('colorscheme seoul256')
            end
        }
        use {
            'neovim/nvim-lspconfig',
            after = 'seoul256.vim',
            config = lspconfig
        }
        use {'sheerun/vim-polyglot'}
        use {
            'Chiel92/vim-autoformat',
            config = function()
                local host = require('util').host
                vim.g.autoformat_autoindent = 0
                vim.g.autoformat_retab = 0
                vim.g.autoformat_remove_trailing_spaces = 0
                vim.g.formatdef_custom_ex = '"/home/marc/Code/sensor/build/tools/format_code.sh -f ".bufname("%")'
                vim.g.formatters_c = {'custom_ex'}
                vim.g.formatters_cpp = {'custom_ex'}
                vim.g.formatters_yacc = {'custom_ex'}
                vim.g.formatters_python = {'black'}
                if host.disable_lsp_fmt['clangd'] then
                    vim.cmd([[
                        autocmd BufWritePre *.c,*.cc,*.h,*.y Autoformat
                    ]])
                end
                if host.disable_lsp_fmt['pyls'] then
                    vim.cmd([[
                        autocmd FileType python autocmd BufWritePre <buffer> Autoformat
                    ]])
                end
            end
        }
        use {'machakann/vim-sandwich'}
        use {'mhinz/vim-signify'}
        use {'kshenoy/vim-signature'}
        use {
            'tpope/vim-fugitive',
            config = function()
                local util = require('util')
                util.map('n', '<leader>B', ':Git blame<cr>')
            end
        }
        use {
            'ludovicchabant/vim-gutentags',
            config = function()
                local cmd = 'git ls-files -co '
                local exts = {
                    'c', 'h', 'cc', 'go', 'py', 'rs', 'ts', 'tsx'
                }
                for _, ext in pairs(exts) do
                    cmd = cmd .. string.format('\'*.%s\' ', ext)
                end
                vim.g.gutentags_define_advanced_commands = 1
                vim.g.gutentags_ctags_exclude = {'vendor/*', 'linux/*'}
                vim.g.gutentags_project_root = {'.git'}
                vim.g.gutentags_file_list_command = {
                    markers = {
                        ['.git'] = cmd,
                    }
                }
            end
        }
        use {
            'vimwiki/vimwiki',
            config = function()
                local util = require('util')
                util.map('n', '<leader>ww', ':VimwikiIndex<cr>')
                vim.g.vimwiki_list = {{path = '~/Private/wiki'}}
            end
        }
        use {
            'nvim-telescope/telescope.nvim',
            requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}},
            config = function()
                local telescope = require('telescope')
                local actions = require('telescope.actions')
                local util = require('util')
                telescope.setup({
                    defaults = {
                        mappings = {
                            i = {
                                ['<tab>'] = function(bufnr)
                                    actions.toggle_selection(bufnr)
                                    actions.move_selection_next(bufnr)
                                end,
                                ['<s-tab>'] = function(bufnr)
                                    actions.move_selection_previous(bufnr)
                                    actions.toggle_selection(bufnr)
                                end,
                                ['<c-q>'] = function(bufnr)
                                    actions.smart_send_to_qflist(bufnr)
                                    vim.cmd('copen')
                                end
                            },
                            n = {
                                ['<tab>'] = function(bufnr)
                                    actions.toggle_selection(bufnr)
                                    actions.move_selection_next(bufnr)
                                end,
                                ['<s-tab>'] = function(bufnr)
                                    actions.move_selection_previous(bufnr)
                                    actions.toggle_selection(bufnr)
                                end,
                                ['<c-q>'] = function(bufnr)
                                    actions.smart_send_to_qflist(bufnr)
                                    vim.cmd('copen')
                                end
                            },
                        }
                    }
                })
                local opts = {
                    theme = 'get_dropdown',
                    prompt_prefix = '🔍\\ \\ ',
                }
                local buf_opts = util.update(opts, {
                    show_all_buffers = 'true',
                    sort_lastused = 'true',
                    default_selection_index = '1',
                })
                local mappings = {
                    {',f', 'find_files', opts},
                    {',b', 'buffers', buf_opts},
                    {',g', 'live_grep', opts},
                    {'<leader>g', 'grep_string', opts},
                    {',t', 'tags', opts}
                }
                for _, v in ipairs(mappings) do
                    local map, cmd, opts = v[1], v[2], v[3]
                    local out = ''
                    for k, v in pairs(opts) do
                        out = string.format('%s%s=%s ', out, k, v)
                    end
                    util.map('n', map, string.format(
                        ':Telescope %s %s<cr>', cmd, out)
                    )
                end
            end
        }
        use {'nvim-treesitter/nvim-treesitter', run = 'TSUpdate'}
        use {
            'nvim-lua/completion-nvim',
            config = function()
                vim.cmd([[
                    imap <tab> <Plug>(completion_smart_tab)
                    imap <s-tab> <Plug>(completion_smart_s_tab)
                ]])
            end
        }
        use {
            'kyazdani42/nvim-tree.lua',
            requires = {'kyazdani42/nvim-web-devicons', opt = true},
            config = function()
                local util = require('util')
                util.map('n', '<leader>t', ':NvimTreeToggle<cr>')
            end
        }
        use {
            'hoob3rt/lualine.nvim',
            requires = {'kyazdani42/nvim-web-devicons', opt = true},
            config = function()
                require('lualine').setup({
                    options = {
                        theme = 'seoul256',
                        section_separators = {'', ''},
                        component_separators = {'', ''},
                        icons_enabled = true,
                    },
                    sections = {
                        lualine_a = {{'mode', upper = true}},
                        lualine_b = {{'branch', icon = ''}},
                        lualine_c = {{'filename', file_status = true}},
                        lualine_x = {},
                        lualine_y = {'filetype'},
                        lualine_z = {'location'},
                    },
                    inactive_sections = {}
                })
            end
        }
    end)
end

return M
