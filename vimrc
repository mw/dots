filetype off

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-fugitive'
Plug 'tomtom/quickfixsigns_vim'
Plug 'tomtom/tlib_vim'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'kshenoy/vim-signature'
Plug 'mbbill/undotree'
Plug 'vim-scripts/fountain.vim'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'qpkorr/vim-bufkill'
Plug 'ludovicchabant/vim-gutentags'
Plug 'Chiel92/vim-autoformat'
Plug 'leafgarland/typescript-vim'
Plug 'ianks/vim-tsx'
Plug 'tpope/vim-fugitive'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'machakann/vim-sandwich'
Plug 'triglav/vim-visual-increment'
Plug 'junegunn/seoul256.vim'
Plug 'vimwiki/vimwiki'
Plug 'nathangrigg/vim-beancount'

call plug#end()

if &term =~ "screen"
    set t_#4=[d
    set t_%i=[c
endif

" preferences
set backspace=2
set t_Co=256
set tenc=utf-8
set enc=utf-8
set showmatch
set ruler
set showcmd
set updatetime=300
set shortmess+=c
set laststatus=2
set tabstop=4
set shiftwidth=4
set nohlsearch
set expandtab
set smarttab
set nowrap
set linebreak
set showbreak=→
set nolist "required for linebreak to work
set listchars=tab:\|\ ,extends:>,precedes:<
set noerrorbells
set novisualbell
set history=4000
set magic
set report=0
set shell=zsh
set backup
set writebackup
set backupdir=/tmp,.
set number
set autowrite
set incsearch
set mouse=a
set mousehide
set noshiftround
set nolazyredraw
set wildchar=<TAB>
set nocompatible
set hidden
set grepprg=rg\ -n\ -S\ $*
set wildmenu
set wildmode=list:longest
set winminheight=0
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.swp,.git,.svn
set wildignore+=doc/**,gui/doc/**,gui/install/**,portal/install/**,portal/doc/**
set wildignore+=build
set wildignore+=dist
set wildignore+=install
set wildignore+=node_modules
set whichwrap=h,l,b,<,>,[,]
set pastetoggle=<Insert>
set ignorecase
set nojoinspaces
set textwidth=80
set formatoptions=tcroqn
set complete -=k complete+=k
set completeopt=menuone,longest,preview
set viminfo-=! viminfo+=!
set sessionoptions=buffers
set signcolumn=yes
set conceallevel=0
set statusline=%f
set statusline+=\ %h%m%r%w
set statusline+=\ (%{strlen(&ft)?&ft:'none'}
set statusline+=\ %{strlen(&fenc)?&fenc:&enc}
set statusline+=\ %{&fileformat})
set statusline+=%=
set statusline+=%{synIDattr(synID(line('.'),col('.'),1),'name')}
set statusline+=\ %c,%l/%L\ (%P)
set spelllang=en_us
set noshowmode
set directory=$HOME/.vim/swap
set timeoutlen=1000
set ttimeoutlen=0
set nofoldenable
syntax on

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <c-space> coc#refresh()

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" Remap for do codeAction of current line
nmap <leader>ac <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf <Plug>(coc-fix-current)

let g:rustfmt_autosave = 1

let g:lightline = {'colorscheme': 'wombat'}

let g:vimwiki_list = [{'path': '~/Private/wiki'}]

let c_space_errors = 1
let python_highlight_space_errors = 1
let python_highlight_all  = 1
let java_space_errors = 1

colorscheme seoul256
highlight clear SignColumn

" Show trailing whitespace and spaces before a tab:
highlight ExtraWhitespace ctermbg=black guibg=black
match ExtraWhitespace /\s\+$\| \+\ze\t/

let hostfile = $HOME . '/.vim/hosts/' . hostname() . '.vim'
if filereadable(hostfile)
    exe 'source ' . hostfile
endif

let g:coc_global_extensions = ['coc-json', 'coc-clangd', 'coc-python', 'coc-rls', 'coc-go']

let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0

if !executable('ctags')
    let g:gutentags_enabled = 0
endif
let g:gutentags_define_advanced_commands = 1
let g:gutentags_generate_on_new = 0
let g:gutentags_ctags_tagfile = '.tags'
let g:gutentags_project_root = ['.tags']
let g:gutentags_file_list_command = {
    \ 'markers': {
        \ '.git': 'git ls-files -co --exclude-standard',
        \ },
    \ }

if exists("+undofile")
    set undodir=~/.vim/undo
    set undofile
    set undolevels=8000
    set undoreload=30000
endif

" keybindings
nnoremap ,s :source ~/.vimrc<CR>
nnoremap ,v :edit ~/.vimrc<CR>
nnoremap ,T :NERDTreeToggle<CR>
nnoremap ,U :UndotreeToggle<CR>

nnoremap <silent> <C-L> :redraw<cr>:call popup_clear()<cr>:lclose<cr>

nnoremap <space> zz
vnoremap <space> zz

noremap :E :e
noremap :R :r
noremap :Q :q
noremap :WQ :wq
noremap :Wq :wq
noremap :qwa :wqa
noremap :W :w

" show/hide long lines
noremap <silent> <Leader>L :match ErrorMsg '\%>80v.\+'<cr>
noremap <silent> <Leader>C :match<cr>

nnoremap ,M :set makeprg=<c-r>=&makeprg<cr>
nnoremap ,m :make<cr>

nnoremap <Leader><Leader> :set invpaste paste?<CR>
nnoremap <Leader>n :set invnumber number?<CR>
nnoremap ,w :call <SID>WrapToggle()<CR>
nmap <silent> ,r <Plug>(coc-references)
nmap <silent> ,d <Plug>(coc-definition)
nmap <silent> ,D <Plug>(coc-type-definition)
nmap <silent> ,i <Plug>(coc-implementation)
nmap <silent> <silent> ,S :<C-u>CocList -I symbols<cr>

function! s:WrapToggle()
    set invwrap wrap?
    " only want these if wrap is set
    if &wrap
        nnoremap 0 g0
        nnoremap ^ g^
        nnoremap $ g$
    else
        nnoremap 0 0
        nnoremap ^ ^
        nnoremap $ $
    endif
endfunction

" related to the above---these are always fine
nnoremap j gj
nnoremap k gk

 function! s:build_quickfix_list(lines)
   call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
   copen
   cc
 endfunction

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-o': 'open',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }

let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'
let $FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
command! -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

command! -nargs=? -complete=dir GFiles
  \ call fzf#vim#gitfiles(<q-args>, fzf#vim#with_preview(), <bang>0)

function! s:line_handler(l)
  let keys = split(a:l, ': ')
  exec 'buf' keys[0]
  exec keys[1]
  normal! ^zz
endfunction

function! s:buffer_lines()
  let res = []
  for b in filter(range(1, bufnr('$')), 'buflisted(v:val)')
    call extend(res, map(getbufline(b,0,"$"), 'b . ": " . (v:key + 1) . ": " . v:val '))
  endfor
  return res
endfunction

command! FZFLines call fzf#run({
\   'source':  <sid>buffer_lines(),
\   'sink':    function('<sid>line_handler'),
\   'options': '--extended --nth=3..',
\   'down':    '60%'
\})

nnoremap <silent> ,b :Buffers<CR>
nnoremap <silent> ,t :Tags<CR>
nnoremap <silent> ,f :Files<CR>
nnoremap <silent> ,g :GFiles<CR>
"nnoremap <silent> ,l :FZFLines<CR>

if has('nvim')
    noremap <C-Z> :terminal<CR>i
else
    noremap <C-Z> :shell<CR>
endif

" search and replace cword/selection (normal and visual modes)
nnoremap <Leader>f :%s/\<<c-r>=expand("<cword>")<cr>\>//gc<left><left><left>

" case sensitive
nnoremap <Leader>F :%s/\<<c-r>=expand("<cword>")<cr>\>//gcI<left><left><left><left>
vnoremap <Leader>f "hy:%s/<c-r>=escape("<c-r>h", "\\\/")<cr>//gc<left><left><left>
vnoremap <Leader>F "hy:%s/<c-r>=escape("<c-r>h", "\\\/")<cr>//gcI<left><left><left><left>

" grep
nnoremap <Leader>g :Rg <c-r>=expand("<cword>")<cr>
vnoremap <Leader>g "hy:Rg <c-r>h
nnoremap <silent> ,q :call <SID>WinType("quickfix")<cr>:cw<cr>
nnoremap ,n :cn<cr>
nnoremap ,p :cp<cr>

function! s:WinType(type)
    if a:type == "location"
        nnoremap ,n :lnext<cr>
        nnoremap ,p :lprevious<cr>
    else "quickfix
        nnoremap ,n :cn<cr>
        nnoremap ,p :cp<cr>
    endif
endfunction

" underline the current line with dashes
noremap <Leader>u Yp:s/./-/g<CR>:let @/=""<CR>
noremap <Leader>U Yp:s/./=/g<CR>:let @/=""<CR>

" remove trailing whitespace
nnoremap <Leader>ws :%s/\s\+$//e<cr>``

" search in a visual block only
vnoremap / <Esc>/\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l
vnoremap ? <Esc>?\%><C-R>=line("'<")-1<CR>l\%<<C-R>=line("'>")+1<CR>l

noremap <silent> <Leader>hc :let @/ = '\%' . virtcol('.') .  'v' <bar> set hls<CR>

" command-line mode bindings
cnoremap <c-a> <home>
cnoremap <c-e> <end>
cnoremap <c-k> <c-u>
cnoremap Â <S-Left>
cnoremap Æ <S-Right>
cnoremap  <c-W>
inoremap Â <S-Left>
inoremap Æ <S-Right>
nnoremap <silent> Q :BD!<cr>
nnoremap <C-n> :bn<cr>
nnoremap <C-p> :bp<cr>

if has("gui")
    set guioptions=
    " disable audio error bell in MacVim
    set visualbell
    set t_vb=
endif

" autocmds
filetype plugin on
filetype indent on

if has("autocmd")
    autocmd FileType c,cpp set autoindent cindent cinoptions=:0t0j1(0u0w1
    autocmd BufNewFile,BufRead *.txt setlocal filetype=text
    autocmd BufNewFile,BufRead *.md setlocal filetype=markdown
    autocmd FileType gitcommit setlocal spell nocindent
    autocmd FileType c,cpp setlocal path+=/usr/include/**
    autocmd FileType c,cpp setlocal path+=/usr/local/include/**
    autocmd FileType go setlocal noexpandtab
    autocmd FileType markdown,text,none setlocal noci nocin noai nosi spell
    autocmd FileType fountain setlocal noci nocin noai nosi
    autocmd BufNewFile *.{h,hpp} call <SID>InsertGates()
	autocmd CursorHold * silent call CocActionAsync('highlight')
    autocmd BufWritePre *.go :call CocAction('runCommand', 'editor.action.organizeImport')
endif

" add include guards for new header files
function! s:InsertGates()
    let gatename = substitute(toupper(expand("%:t")), "\\.", "_", "g")
    execute "normal i#ifndef " . gatename
    execute "normal o#define " . gatename
    execute "normal Go#endif /* " . gatename . " */"
    normal kk
endfunction
