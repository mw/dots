-- plugins
local util = require('util')
local plugins = require('plugins')

plugins.init()

-- global options
util.opt('o', 'backspace', 'indent,eol,nostop')
util.opt('o', 'backup', true)
util.opt('o', 'backupdir', '/tmp,.')
util.opt('o', 'completeopt', 'menuone,noinsert,noselect')
util.opt('o', 'foldenable', false)
util.opt('o', 'hidden', true)
util.opt('o', 'hlsearch', false)
util.opt('o', 'ignorecase', true)
util.opt('o', 'joinspaces', false)
util.opt('o', 'laststatus', 2)
util.opt('o', 'mouse', 'a')
util.opt('o', 'report', 0)
util.opt('o', 'sessionoptions', 'buffers')
util.opt('o', 'shortmess', 'filnxtToOFc')
util.opt('o', 'showbreak', '→')
util.opt('o', 'showcmd', false)
util.opt('o', 'showmatch', true)
util.opt('o', 'showmode', false)
util.opt('o', 'smartcase', true)
util.opt('o', 'smarttab', true)
util.opt('o', 'termguicolors', true)
util.opt('o', 'undolevels', 8000)
util.opt('o', 'undoreload', 30000)
util.opt('o', 'whichwrap', 'h,l,<,>,[,]')
util.opt('o', 'wildignore', '*.o,*.bak,*.pyc,*.swp,.git,node_modules')
util.opt('o', 'wildmode', 'list:longest')
util.opt('o', 'writebackup', true)

-- buffer options
util.opt('b', 'expandtab', true)
util.opt('b', 'formatoptions', 'tcroqnj')
util.opt('b', 'shiftwidth', 4)
util.opt('b', 'spelllang', 'en_us')
util.opt('b', 'syntax', 'on')
util.opt('b', 'tabstop', 4)
util.opt('b', 'textwidth', 80)
util.opt('b', 'undofile', true)

-- window options
util.opt('w', 'linebreak', true)
util.opt('w', 'number', true)
util.opt('w', 'signcolumn', 'auto:1')
util.opt('w', 'wrap', false)

-- key mappings
util.map('v', '<space>', 'zz')
util.map('n', '<space>', 'zz')

util.map('i', '<s-tab>', 'pumvisible() ? "\\<C-p>" : "\\<tab>"', {expr = true})
util.map('i', '<tab>', 'pumvisible() ? "\\<C-n>" : "\\<tab>"', {expr = true})

util.map('n', '<leader><leader>', ':set invpaste paste?<cr>')
util.map('n', '<leader>n', ':set invnumber number?<cr>')
util.map('n', ',w', ':set invwrap wrap?<cr>')

util.map('n', '<c-z>', ':terminal<cr>i')
util.map('n', '<c-n>', ':bn<cr>')
util.map('n', '<c-p>', ':bp<cr>')
util.map('n', 'Q', ':bd!<cr>')
util.map('n', ',v', ':e ~/.config/nvim/init.lua<cr>')
util.map('n', ',s', ':luafile ~/.config/nvim/init.lua<cr>')

util.map('n', ',q', ':cwindow<cr>')
util.map('n', ',n', ':cnext<cr>')
util.map('n', ',p', ':cprev<cr>')

-- autocommands
vim.cmd('autocmd TermEnter * setlocal nonumber')

-- trailing spaces
vim.cmd('highlight ExtraWhitespace guifg=#ff0000 guibg=#555555')
vim.cmd('match ExtraWhitespace /\\s\\+$/')
