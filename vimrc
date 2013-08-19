filetype off

set rtp+=~/.vim/bundle/vundle
call vundle#rc()

Bundle 'gmarik/vundle'
Bundle 'fholgado/minibufexpl.vim'
Bundle 'godlygeek/csapprox'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-repeat'
Bundle 'tpope/vim-surround'
Bundle 'FuzzyFinder'
Bundle 'javacomplete'
Bundle 'thinca/vim-guicolorscheme'
Bundle 'L9'
Bundle 'tomtom/quickfixsigns_vim'
Bundle 'tomtom/tlib_vim'
Bundle 'kana/vim-arpeggio'
Bundle 'scrooloose/nerdcommenter'
Bundle 'scrooloose/nerdtree'
Bundle 'scrooloose/syntastic'
Bundle 'Valloric/YouCompleteMe'
Bundle 'git://git.wincent.com/command-t.git'
Bundle 'MarcWeber/vim-addon-mw-utils.git'
Bundle 'Lokaltog/vim-powerline'
Bundle 'kshenoy/vim-signature'
Bundle 'jnwhiteh/vim-golang'
Bundle 'leafgarland/typescript-vim'

if &term =~ "screen"
    set t_#4=[d
    set t_%i=[c
endif

" preferences
set backspace=2
set t_Co=256
set autoindent
set cindent
set cinoptions=:0t0j1(0u0w1
set tenc=utf-8
set enc=utf-8
set showmatch
set ruler
set showcmd
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
colorscheme inkpot
set showmode
set backup
set writebackup
set backupdir=/tmp,.
set number
set autowrite
set incsearch
set mouse=a
set mousehide
set shiftround
set nolazyredraw
set wildchar=<TAB>
set nocompatible
set hidden
set grepprg=grep\ -nH\ -RIis\ --exclude=tags\ --exclude=doc\ --exclude=\\*.tab.c\ $*
set wildmenu
set wildmode=list:longest
set background=light
set winminheight=0
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.swp,.git,.svn
set wildignore+=doc/**,gui/doc/**,gui/install/**,portal/install/**,portal/doc/**
set wildignore+=node_modules
set wildignore+=*/CVS/
set whichwrap=h,l,b,<,>,[,]
set pastetoggle=<Insert>
set ignorecase
set nojoinspaces
set textwidth=79
set formatoptions=tcroqn
set complete -=k complete+=k
set completeopt=menuone,longest,preview
set viminfo-=! viminfo+=!
set sessionoptions=buffers
set statusline=%f
set statusline+=\ %h%m%r%w
set statusline+=\ (%{strlen(&ft)?&ft:'none'}
set statusline+=\ %{strlen(&fenc)?&fenc:&enc}
set statusline+=\ %{&fileformat})
set statusline+=%=
set statusline+=%{synIDattr(synID(line('.'),col('.'),1),'name')}
set statusline+=\ %c,%l/%L\ (%P)
syntax on

let g:CommandTCancelMap=["<ESC>", "<C-c>", "C-["]
let g:CommandTMaxFiles=40000
let g:CommandTMaxDepth=40

let g:ycm_global_ycm_extra_conf = "~/.vim/.ycm_extra_conf.py"
let g:ycm_min_num_of_chars_for_completion = 8

let c_space_errors = 1
let python_highlight_space_errors = 1
let python_highlight_all  = 1
let java_space_errors = 1

" Show trailing whitespace and spaces before a tab:
highlight ExtraWhitespace ctermbg=black guibg=black
match ExtraWhitespace /\s\+$\| \+\ze\t/

if has("conceal")
    set conceallevel=2
    let g:tex_conceal="adgms"
    let g:no_rust_conceal=1
endif

" folding
set foldenable
set foldmarker={,}
set foldmethod=marker
set foldtext=substitute(getline(v:foldstart),'{.*','{...}','')
set foldcolumn=0
set foldlevelstart=100

if exists("+undofile")
    set undodir=~/.vim/undo
    set undofile
    set undolevels=8000
    set undoreload=30000
endif

let IspellLang = 'english'

" keybindings
nnoremap ,s :source ~/.vimrc<CR>
nnoremap ,v :edit ~/.vimrc<CR>
nnoremap ,T :NERDTreeToggle<CR>

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

" arpeggio plugin mappings
function! s:LoadArpeggio()
   if exists(":Arpeggio")
        Arpeggio inoremap <silent> jk <ESC>
    endif
endfunction
autocmd VimEnter * call <SID>LoadArpeggio()

nnoremap ,m :make<cr>

" bufkill plugin
let g:BufKillVerbose = 0
nnoremap <silent> Q :BD!<cr>

nnoremap <Leader><Leader> :set invpaste paste?<CR>
nnoremap <Leader>n :set invnumber number?<CR>
nnoremap ,w :call <SID>WrapToggle()<CR>

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

" fuzzyfinder functions
nnoremap <silent> ,c :FufChangeList<CR>
nnoremap <silent> ,b :FufBuffer<CR>
nnoremap <silent> ,j :FufJumpList<CR>
nnoremap <silent> ,Q :FufQuickfix<CR>
nnoremap <silent> ,t :FufTag<CR>
nnoremap <silent> ,h :FufHelp<CR>
nnoremap <silent> <C-]> :FufTagWithCursorWord<CR>

" command-t plugin
nnoremap <silent> ,f :CommandT<CR>
nnoremap <silent> ,F :CommandTFlush<CR>

noremap <C-Z> :shell<CR>

" search and replace cword/selection (normal and visual modes)
nnoremap <Leader>f :%s/\<<c-r>=expand("<cword>")<cr>\>//gc<left><left><left>
" case sensitive
nnoremap <Leader>F :%s/\<<c-r>=expand("<cword>")<cr>\>//gcI<left><left><left><left>
vnoremap <Leader>f "hy:%s/<c-r>=escape("<c-r>h", "\\\/")<cr>//gc<left><left><left>
vnoremap <Leader>F "hy:%s/<c-r>=escape("<c-r>h", "\\\/")<cr>//gcI<left><left><left><left>

" grep
nnoremap <Leader>g :grep "<c-r>=expand("<cword>")<cr>" *<left><left><left>
vnoremap <Leader>g "hy:grep "<c-r>h" *<left><left><left>

" open javadoc using word under cursor (requires surfraw and w3m)
nnoremap <Leader>j :!sr javasun <c-r>=expand("<cword>")<cr> -t -browser=w3m<cr>

nnoremap <C-n> :bn<cr>
nnoremap <C-p> :bp<cr>

nnoremap <silent> ,q :call <SID>WinType("quickfix")<cr>:cw<cr>
nnoremap <silent> ,l :call <SID>WinType("location")<cr>:lw<cr>
nnoremap ,n :cn<cr>
nnoremap ,p :cp<cr>
nnoremap ,o :!open %<.pdf<cr><cr>
nnoremap <silent> ,C :!ctags -R --exclude=".*" > /dev/null 2>&1 &<cr>

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
inoremap  <c-W>

" minibufexplorer options
let g:miniBufExplMaxHeight=5
let g:miniBufExplorerMoreThanOne=2
let g:miniBufExplUseSingleClick=1
let g:miniBufExplCheckDupeBufs=0

" taglist options
let Tlist_Ctags_Cmd = '/usr/bin/ctags'
let Tlist_Use_Right_Window = 0
let Tlist_cpp_settings = 'c++;c:classes;f:functions'
let Tlist_c_settings = 'c;f:functions'
let Tlist_WinWidth = 30
let Tlist_Inc_Winwidth = 0
let Tlist_Compact_Format = 1
let Tlist_Exit_OnlyWindow = 1

nnoremap <silent> <Leader>t :TlistToggle<CR>

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
    autocmd BufNewFile,BufRead *.less setlocal filetype=less
    autocmd BufNewFile,BufRead *.mxml setlocal filetype=mxml
    autocmd BufNewFile,BufRead *.as setlocal filetype=actionscript
    autocmd BufNewFile,BufRead *.txt setlocal filetype=text
    autocmd BufNewFile,BufRead *.json setlocal filetype=json
    autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
    autocmd BufNewFile,BufRead SCons* setlocal filetype=scons
    autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
    autocmd FileType gitcommit setlocal spell nocindent
    autocmd FileType haskell setlocal omnifunc=haskellcomplete#CompleteHaskell
    autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
    autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
    autocmd FileType rb setlocal omnifunc=rubycomplete#Complete
    autocmd FileType sql setlocal omnifunc=sqlcomplete#Complete
    autocmd FileType html setlocal omnifunc=htmlcomplete#CompleteTags
    autocmd FileType java setlocal omnifunc=javacomplete#Complete
    autocmd FileType c,cpp setlocal path+=/usr/include/**
    autocmd FileType c,cpp setlocal path+=/usr/local/include/**

	autocmd FileType text setlocal noci nocin noai nosi spell
	autocmd BufEnter *.py noremap <f2> :w\|!python %<cr>
    autocmd BufEnter *.{scm,lisp} setlocal lisp
	autocmd BufNewFile mutt-* setlocal tw=76
	autocmd BufNewFile *.{h,hpp} call <SID>InsertGates()
	autocmd BufEnter * call <SID>CheckForLastWindow()
    autocmd FileType qf setlocal wrap
    autocmd FileType c,cpp,cpp.c inoremap < <<C-R>=<SID>HeaderComplete()<CR>

    autocmd BufNewFile,BufRead *.md setlocal filetype=markdown

    autocmd CursorMovedI * if pumvisible() == 0|pclose|endif
    autocmd InsertLeave * if pumvisible() == 0|pclose|endif
endif

function! s:HeaderComplete()
    let linestart = getline(".")[0 : col(".") - 2]
    let hpos = stridx(getline("."), "<")

    if linestart =~ "#include\\s*<\\s*"
        if !exists("g:header_list")
            " get all headers, filter out directories, then strip the
            " /usr/include/ and /usr/include/c++/{version} prefixes
            let g:header_list = map(filter(split(globpath('/usr/include/,/usr/local/include/', '**/*')),
                        \ '!isdirectory(v:val)'),
                        \ 'substitute(v:val, "/usr/include\\(/c++/\\(\\d.\\)*\\d\\)*/", "", "")')
        endif
        let prefix = getline(".")[hpos+2:]

        " filter headers by matching prefix
        let match_list = filter(g:header_list, 'v:val =~ prefix . ".*$"')

        call complete(hpos+2, match_list)
        " return <c-p> so that first match text is not inserted
        return "\<c-p>"
    else
        return ''
    endif
endfunction

" allows gf command to open python modules from import commands
if has('python')
python << EOF
import os
import sys
import vim
for p in sys.path:
    if os.path.isdir(p):
        vim.command(r"set path+=%s" % (p.replace(" ", r"\ ")))
EOF
endif

" simple mappings for running projects
let g:projruncmd = ""
nnoremap ,R :call <SID>PromptRun()<CR>
nnoremap ,r :!%< <CR>

nnoremap ,M :set makeprg=<c-r>=&makeprg<cr>

function! s:PromptRun()
    let g:projruncmd = input("run command: ", g:projruncmd, "shellcmd")
    nnoremap ,r :!<c-r>=g:projruncmd<CR><CR>
endfunction

function! s:CheckForLastWindow()
    " if the window is quickfix go on
    if &buftype=="quickfix"
        " if this window is last on screen, quit without warning
        if winbufnr(2) == -1
            quit!
        endif
    endif
endfunction

" add include guards for new header files
function! s:InsertGates()
        let gatename = substitute(toupper(expand("%:t")), "\\.", "_", "g")
        execute "normal i#ifndef " . gatename
        execute "normal o#define " . gatename
        execute "normal Go#endif /* " . gatename . " */"
        normal kk
endfunction
