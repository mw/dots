vim.cmd('packadd packer.nvim')

local M = {}
local packer = require('packer')

function lspconfig()
    local cfg = require('lspconfig')
    local completion = require('completion')
    local servers = {
        "pyright",
        "rust_analyzer",
        "clangd",
        "tsserver",
        "gopls"
    }
    local function on_attach(client, bufnr)
        local function opt(...)
            vim.api.nvim_buf_set_option(bufnr, ...)
        end
        local function map(...)
            vim.api.nvim_buf_set_keymap(bufnr, ...)
        end
        -- Mappings.
        local opts = {noremap=true, silent=true}
        map('n', ',d', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        map('n', ',D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        map('n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        map('n', '<leader>f', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        map('n', ',r', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        map('n', ',N', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
        map('n', ',P', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
        map('n', ',q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

        if client.resolved_capabilities.document_formatting then
            vim.cmd([[
                autocmd BufWritePost * lua vim.lsp.buf.formatting()<cr>
            ]])
        end
        completion.on_attach(client, bufnr)
    end
    for _, lsp in ipairs(servers) do
        cfg[lsp].setup({on_attach = on_attach})
    end
end

function M.init()
    local util = require('util')
    util.map('n', '<leader>pc', ':PackerCompile<cr>')
    util.map('n', '<leader>ps', ':PackerSync<cr>')

    packer.startup(function(use)
        use {'wbthomason/packer.nvim', opt = true}
        use {
            'neovim/nvim-lspconfig',
            config = lspconfig
        }
        use {'sheerun/vim-polyglot'}
        use {'Chiel92/vim-autoformat'}
        use {'machakann/vim-sandwich'}
        use {'kshenoy/vim-signature'}
        use {'ludovicchabant/vim-gutentags'}
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
                                ["<tab>"] = function(bufnr)
                                    actions.toggle_selection(bufnr)
                                    actions.move_selection_next(bufnr)
                                end,
                                ["<s-tab>"] = function(bufnr)
                                    actions.move_selection_previous(bufnr)
                                    actions.toggle_selection(bufnr)
                                end,
                                ["<c-q>"] = function(bufnr)
                                    actions.smart_send_to_qflist(bufnr)
                                    vim.cmd("copen")
                                end
                            },
                            n = {
                                ["<tab>"] = function(bufnr)
                                    actions.toggle_selection(bufnr)
                                    actions.move_selection_next(bufnr)
                                end,
                                ["<s-tab>"] = function(bufnr)
                                    actions.move_selection_previous(bufnr)
                                    actions.toggle_selection(bufnr)
                                end,
                                ["<c-q>"] = function(bufnr)
                                    actions.smart_send_to_qflist(bufnr)
                                    vim.cmd("copen")
                                end
                            },
                        }
                    }
                })
                local mappings = {
                    {',f', 'find_files'},
                    {',b', 'buffers'},
                    {',g', 'live_grep'},
                    {'<leader>g', 'grep_string'},
                    {',t', 'tags'}
                }
                local opts = {
                    theme = 'get_dropdown',
                    prompt_prefix = '🔍\\ \\ ',
                    show_all_buffers = 'true',
                }
                local out = ""
                for k, v in pairs(opts) do
                    out = string.format("%s%s=%s ", out, k, v)
                end
                for _, v in ipairs(mappings) do
                    local map, cmd = v[1], v[2]
                    util.map('n', map, string.format(
                        ':Telescope %s %s<cr>', cmd, out)
                    )
                end
            end
        }
        use {'nvim-treesitter/nvim-treesitter', run = 'TSUpdate'}
        use {
            'junegunn/seoul256.vim',
            config = function()
                vim.g.seoul256_background = 236
                vim.cmd('colorscheme seoul256')
            end
        }
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
                require('lualine').status({
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
