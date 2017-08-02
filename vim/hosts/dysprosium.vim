let g:formatdef_custom_ex='"/home/marc/Code/depot/build/tools/format_code.sh -f ".bufname("%")'
let g:formatters_c=['custom_ex']
let g:formatters_cpp=['custom_ex']
let g:formatters_yacc=['custom_ex']
let g:formatdef_black='"black --fast --line-length 80 -q -"'
let g:formatters_python=['black']

let g:gutentags_ctags_exclude = ['*.html', '*.css', '*.xml', '*.json',
 \ 'htmlgui/src/vendor', 'linux', 'hopcloud', 'doc*', 'media',
 \ 'htmlgui/assets', 'Makefile']

if has("autocmd")
    autocmd BufWritePre *.c,*.cc,*.h,*.y,*.py Autoformat
endif
