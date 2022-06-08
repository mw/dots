local scopes = {o = vim.o, b = vim.bo, w = vim.wo}

function opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= 'o' then scopes['o'][key] = value end
end

function map(mode, lhs, rhs, opts)
    local options = {noremap = true, silent = true}
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

local install_path = vim.fn.stdpath('data') ..
    '/site/pack/packer/start/packer.nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    packer_bootstrap = vim.fn.system({
        'git', 'clone', '--depth', '1',
        'https://github.com/wbthomason/packer.nvim',
        install_path
    })
end

require('packer').startup(function(use)
    use {
        'wbthomason/packer.nvim',
        config = function()
            map('n', '<leader>pc', ':PackerCompile<cr>')
            map('n', '<leader>ps', ':PackerSync<cr>')
        end
    }
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
            vim.cmd([[
                autocmd BufWritePre *.c,*.cc,*.h,*.y Autoformat
            ]])
            vim.cmd([[
                autocmd FileType python autocmd BufWritePre <buffer> Autoformat
            ]])
        end
    }
    use {
        'junegunn/seoul256.vim',
        config = function()
            vim.g.seoul256_background = 236
            vim.cmd('colorscheme seoul256')
        end
    }
    use {
        'neovim/nvim-lspconfig',
        after = {'nvim-cmp', 'seoul256.vim'},
        config = function()
            local cfg = require('lspconfig')
            local servers = {
                {
                    'clangd', {
                        cmd = {"clangd", "--background-index", "--log=verbose"}
                    }
                },
                {'cssls', {}},
                {'html', {}},
                {'jsonls', {}},
                {'rnix', {}},
                {
                    'gopls', {
                        root_dir = cfg.util.root_pattern('Gopkg.toml', 'go.mod', '.git')
                    }
                },
                {'pylsp', {}},
                {'svelte', {}},
                {'rust_analyzer', {}},
                {'tailwindcss', {}},
                {'tsserver', {}}
            }

            local function on_attach(client, bufnr)
                local function map(...)
                    vim.api.nvim_buf_set_keymap(bufnr, ...)
                end
                local opts = {noremap=true, silent=true}
                map('n', ',d', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                map('n', ',D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
                map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
                map('n', '<c-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
                map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                map('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
                map('n', '<leader>f', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
                map('n', ',r', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                map('n', ',N', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
                map('n', ',P', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
                map('n', ',q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

                if client.name ~= "clangd" and client.name ~= "pylsp" and
                    client.resolved_capabilities.document_formatting then
                    vim.cmd([[
                        augroup formatting
                        au!
                        autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting()
                        augroup END
                    ]])
                end

                -- Tone down diagnostics
                for _, hl in ipairs({
                    'DiagnosticVirtualTextHint',
                    'DiagnosticVirtualTextInfo',
                    'DiagnosticVirtualTextWarn',
                    'DiagnosticVirtualTextError'
                }) do
                    vim.cmd('highlight ' .. hl .. ' guifg=#606060')
                end
                for _, hl in ipairs({
                    'DiagnosticLineNrHint',
                    'DiagnosticLineNrInfo',
                    'DiagnosticLineNrWarn',
                    'DiagnosticLineNrError'
                }) do
                    vim.cmd('highlight ' .. hl .. ' guibg=#4B4B4B ' ..
                        ' guifg=#FFA500 gui=bold')
                end
                for _, sign in ipairs({
                    'DiagnosticSignHint',
                    'DiagnosticSignInfo',
                    'DiagnosticSignWarn',
                    'DiagnosticSignError'
                }) do
                    vim.cmd('sign define ' .. sign ..
                        ' text= texthl=DiagnosticSignWarn linehl= ' ..
                        'numhl=DiagnosticLineNrWarn')
                end
                vim.diagnostic.config({underline = false})
            end

            local capabilities = require('cmp_nvim_lsp').update_capabilities(
                vim.lsp.protocol.make_client_capabilities())
            local defaults = {
                on_attach = on_attach,
                capabilities = capabilities
            }
            for _, val in ipairs(servers) do
                local lsp, opts = val[1], update(defaults, val[2])
                cfg[lsp].setup(opts)
            end
        end
    }
    use {'machakann/vim-sandwich'}
    use {'mhinz/vim-signify'}
    use {'kshenoy/vim-signature'}
    use {
        'onsails/lspkind-nvim',
        config = function()
            require('lspkind').init({})
        end
    }
    use {
        'tpope/vim-fugitive',
        config = function()
            map('n', '<leader>B', ':Git blame<cr>')
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
            map('n', '<leader>ww', ':VimwikiIndex<cr>')
            vim.g.vimwiki_list = {{path = '~/Private/wiki'}}
        end
    }
    use {
        'junegunn/fzf.vim',
        requires = {'junegunn/fzf'},
        config = function()
            local mappings = {
                {',f', ':Files'},
                {',b', ':Buffers'},
                {',g', ':Rg'},
                {',t', ':Tags'}
            }
            for _, v in ipairs(mappings) do
                local seq, cmd = v[1], v[2]
                map('n', seq, string.format('%s<cr>', cmd))
            end
        end
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        run = 'TSUpdate',
        config = function()
            require('nvim-treesitter.configs').setup({
                highlight = {
                    enable = true
                }
            })
        end
    }
    use {'hrsh7th/vim-vsnip'}
    use {'hrsh7th/cmp-nvim-lsp'}
    use {
        'hrsh7th/nvim-cmp',
        config = function()
            local cmp = require('cmp')
            cmp.setup({
                completion = {
                    autocomplete = false
                },
                mapping = {
                    ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4)),
                    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4)),
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
    }
    use {
        'kyazdani42/nvim-tree.lua',
        requires = {'kyazdani42/nvim-web-devicons', opt = true},
        config = function()
            map('n', '<leader>t', ':NvimTreeToggle<cr>')
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
    if packer_bootstrap then
        require('packer').sync()
    end
end)

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

map('i', '<s-tab>', 'pumvisible() ? "\\<C-p>" : "\\<tab>"', {expr = true})
map('i', '<tab>', 'pumvisible() ? "\\<C-n>" : "\\<tab>"', {expr = true})

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
vim.cmd('highlight ExtraWhitespace guifg=#ff0000 guibg=#555555')
vim.cmd('match ExtraWhitespace /\\s\\+$/')
