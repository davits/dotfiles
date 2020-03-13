" vim: foldmethod=marker foldmarker={{{,}}}

"{{{ Options carved on the stone

"{{{ Some terminal crap
if $COLORTERM == "gnome-terminal"
    set t_Co=256
elseif &term=="xterm"
    set t_Co=8
    set t_Sb=[4%dm
    set t_Sf=[3%dm
endif
"}}}


" Switch syntax highlighting on, when the terminal has colors
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

set nocompatible         " Use Vim defaults (much better!)
set encoding=utf-8
set fileencodings=utf-8  " switch everything to UTF-8
set bs=indent,eol,start  " allow backspacing over everything in insert mode
set viminfo='20,\"50     " read/write a .viminfo file, don't store more than 50 lines of registers
set history=50           " keep 50 lines of command line history
set mouse=a              " enable mouse
set ruler                " show the cursor position all the time
set incsearch            " enable search as you type
set noerrorbells         " don't beep on errors (seems to be not enought)
set visualbell           " switch to blink-screen, to disable beep
set t_vb=                " switch off that blink-screen too :)
set completeopt-=preview " Turn off preview window on completions
set nowrap               " Do not wrap lines
set number

set hidden               " Vim removes text properties on buffer switch, this option never unloads buffers.

" Tabulation and indenting options according to CD coding style
set expandtab
set cindent
set shiftwidth=4
set tabstop=4
set softtabstop=4

"set relativenumber
"set nofixendofline
set fileformats=unix     " We are working only with unix style line endings, will highlight otherwise
set fileformat=unix      " Set buffer line endings style to linux

" Change default grep command to ignore errors
set grepprg=ag\ --nogroup\ --nocolor

"Since Tab and trailing spaces are prohibited by our coding style
"force vim to display them to make more notable to users
set listchars=tab:>-,trail:_
set list

"}}}

"{{{ Indenting options and autocommands

augroup system_vimrc

    autocmd!

    "Set tab to 4 if Tcl or vim file is opened
    "autocmd FileType tcl,vim set shiftwidth=4 tabstop=4 softtabstop=4

    "Switch back to 8 for cpp files
    "autocmd FileType c,cpp set shiftwidth=8 tabstop=8 softtabstop=8

    " Automatically remove trailing spaces
    "autocmd BufWritePre,FileWritePre * silent! %s/\s\+$//

    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif

augroup END

"}}}

"{{{ Movement mappings

"{{{ Map window movements
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
"}}}

"{{{ Map tab commands
nnoremap <A-h> :tabp<CR>
nnoremap <A-j> :tabp<CR>
nnoremap <A-k> :tabn<CR>
nnoremap <A-l> :tabn<CR>
"}}}

"{{{ Map Ctrl+j and Ctrl+k for down/up in command mode
cnoremap <C-j> <down>
cnoremap <C-k> <up>
"}}}

"{{{ Jump between tabs with Alt+1...9 like in terminal
let i = 1
while i < 10
    exec "nnoremap <D-" . i . "> " . i . "gt"
    let i += 1
endwhile
"}}}

"}}} Movement mapping

" {{{ Functionality to jump between corresponding C++ files

let s:exts = {
             \ 'h'  : ['c', 'cc', 'cpp', 'cxx', 'm', 'mm'],
             \ 'hpp': ['cpp', 'cxx', 'cc', 'c', 'impl.hpp', 'mm'],
             \ 'hxx': ['cxx', 'cpp', 'cc', 'c'],
             \ 'c'  : ['h', 'hpp', 'hxx'],
             \ 'cpp': ['hpp', 'hxx', 'h'],
             \ 'cxx': ['hxx', 'hpp', 'h'],
             \ 'cc' : ['hpp', 'hxx', 'h'],
             \ 'm'  : ['h', 'hpp', 'hxx'],
             \ 'mm' : ['hpp', 'hxx', 'h'],
       \ 'impl.hpp' : ['cpp', 'hpp']
             \}

function! s:GoToAlreadyOpened(path)
    for tab in gettabinfo()
        for winID in tab.windows
            let winInfo = getwininfo(winID)[0]
            if a:path == bufname(winInfo.bufnr)
                call win_gotoid(winID)
                return 1
            endif
        endfor
    endfor
    return 0
endfunction

function! s:GoToCorrespondingFile()
    let cfe = expand("%:e")
    let basename = expand("%:r")
    let is_impl = (expand("%:r:e") == 'impl')
    if is_impl
        let cfe = 'impl.' . cfe
        let basename = expand("%:r:r")
    endif
    if !has_key(s:exts, cfe)
        echohl ErrorMsg
        echo "Only " . string(sort(keys(s:exts))) . " files are supported."
        echohl None
        return
    endif
    let found_file = ""
    for ext in s:exts[cfe]
        let fn = basename . '.' . ext
        if glob(fn) != ""
            let found_file = fn
            break
        endif
    endfor
    if found_file == ""
        echohl ErrorMsg
        echo "Corresponding file not found."
        echohl None
        return
    endif
    let cw = expand("<cword>")
    if !s:GoToAlreadyOpened(found_file)
        exec "edit " . found_file
    endif
    try
        if cw != ""
            call search('\<' . cw . '\>')
            normal zz
        endif
    catch
        return
    endtry
endfunction

nnoremap gc :call <SID>GoToCorrespondingFile()<CR>

" }}}

"{{{ Clang format

map <C-T> :py3f /usr/local/opt/llvm/share/clang/clang-format.py<CR>

"}}}

"{{{ Include What You Use

function! s:RunIWYU()
    let l:current_file = expand('%')
    if l:current_file == ""
        echohl ErrorMsg
        echo "Open some file first."
        echohl None
        return
    endif
    echo l:current_file
    let l:compile_db = findfile("compile_commands.json", ".;")
    if l:compile_db == ""
        echohl ErrorMsg
        echo "Can't find compilation database, run :CompileCommands to generate one."
        echohl None
        return
    endif
    let l:mapping_file = ' -- --verbose=3 --quoted_includes_first --mapping_file=' . $VIM_UTILS . '/share/include-what-you-use/cdesigner.imp'
    let l:compile_db_path = fnamemodify(l:compile_db, ':h')
    exec 'terminal iwyu_tool.py -p ' . l:compile_db_path . ' ' . l:current_file . l:mapping_file
endfunction

command! IncludeWhatYouUse call s:RunIWYU()

"}}}

"{{{ Clang Tidy

function! s:RunTidy()
    let l:current_file = expand('%')
    if l:current_file == ""
        echohl ErrorMsg
        echo "Open some file first."
        echohl None
        return
    endif
    echo l:current_file
    let l:compile_db = findfile("compile_commands.json", ".;")
    if l:compile_db == ""
        echohl ErrorMsg
        echo "Can't find compilation database, run :CompileCommands to generate one."
        echohl None
        return
    endif
    let l:compile_db_path = fnamemodify(l:compile_db, ':h')
    exec 'terminal clang-tidy -checks="*,-modernize*" -p ' . l:compile_db_path . ' ' . l:current_file
endfunction

command! ClangTidy call s:RunTidy()

"}}}

"{{{ Plugins and options

"{{{ Memory Usage (may turn off YouCompleteMe)

"function! s:PrintMemoryUsage(message, mem)
"    let s:mb = a:mem / 1024.0
"    let s:gb = s:mb / 1024.0
"    echo printf("%s: %.2fGb (%.1fMb or %sKb)", a:message, s:gb, s:mb, a:mem)
"endfunction
"
"function! s:TotalMemoryUsage()
"    let s:mem = system("ps -u $USER -o rss,comm | \\grep 'vim\\\|python'| awk '{sum += $1} END {print sum}'")
"    " Remove newlines at the end.
"    let s:mem = substitute(s:mem, '\n\+$', '', '')
"    return s:mem
"endfunction
"
"function! s:SelfMemoryUsage()
"    let s:vim_pid = getpid()
"    let s:vim_mem = system("ps -p " . s:vim_pid . " -o rss=")
"    let s:ycm_mem = 0
"    try
"        let s:ycm_pid = youcompleteme#ServerPid()
"        let s:ycm_mem = system("ps -p " . s:ycm_pid . " -o rss=")
"    catch
"    endtry
"    return s:vim_mem + s:ycm_mem
"endfunction
"
"command! ReportMemory call s:PrintMemoryUsage("Memory used by this Vim", s:SelfMemoryUsage())
"command! ReportTotalMemory call s:PrintMemoryUsage("Total memory usage by Vims", s:TotalMemoryUsage())
"
"let s:total_vim_memory = s:TotalMemoryUsage()
"if s:total_vim_memory > 4000000
"    echohl ErrorMsg
"    echo "Your Vims are already using " . s:total_vim_memory . "Kb of RAM in summary, which is far beyond acceptable limits."
"    echo "Turning Off YouCompleteMe plugin."
"    echo "Use :ReportMemory and :ReportTotalMemory commands to find out guilty Vim."
"    echohl Normal
"    let g:loaded_youcompleteme = 1
"endif

"}}}

"{{{ vim-plug options

call plug#begin('~/.vim/plugged')

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' }
"Plug 'Raimondi/delimitMate'
Plug 'altercation/vim-colors-solarized'
Plug 'tpope/vim-fugitive'
Plug 'christoomey/vim-tmux-navigator'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'tikhomirov/vim-glsl'
Plug 'davits/swift.vim'

" LSP client
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/async.vim'
Plug 'davits/vim-lsp'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'prabirshrestha/asyncomplete-file.vim'

Plug 'sourcegraph/javascript-typescript-langserver', {'do': 'rm -rf node_modules/ && npm install && npm run build'}

call plug#end()

"}}} vim-plug options

"{{{ vim-lsp options

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"
imap <c-space> <Plug>(asyncomplete_force_refresh)

let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_highlight_references_enabled = 1
let g:lsp_semantic_enabled = 1
"let g:lsp_log_file = expand('~/vim-lsp.log')

au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
    \ 'name': 'file',
    \ 'whitelist': ['*'],
    \ 'priority': 10,
    \ 'completor': function('asyncomplete#sources#file#completor')
    \ }))

au User lsp_setup call lsp#register_server({
    \ 'name': 'swift-sourcekit',
    \ 'whitelist': ['swift'],
    \ 'cmd': {server_info->[expand('~/bin/swift/bin/sourcekit-lsp')]},
    \ })


function! s:get_cpp_semantic_highlight_info() abort
    hi Namespace guifg=#c17100 gui=italic ctermfg=3 term=italic
    hi UserType guifg=#c17100 ctermfg=3 term=bold
    hi MemberVariable guifg=#6c71c4 ctermfg=13
    "hi StaticMemberVariable guifg=#6c71c4 gui=italic ctermfg=13 term=italic
    "hi GlobalVariable guifg=#93a1a1 gui=italic ctermfg=14 term=italic
    hi Variable guifg=#93a1a1 ctermfg=14
    hi MemberFunction guifg=#268bd2 ctermfg=4
    "hi StaticMemberFunction guifg=#268bd2 gui=italic ctermfg=4 term=italic
    "hi FunctionParameter guifg=#93a1a1 gui=bold ctermfg=14 term=bold
    "hi link Enumerator Constant
    "hi link DyeMacro Macro
    "hi SkippedRange guifg=#657b83 ctermfg=11
    return {
           \'entity.name.function.cpp': 'Function',
           \'entity.name.function.method.cpp': 'MemberFunction',
           \'entity.name.namespace.cpp': 'Namespace',
           \'entity.name.type.class.cpp': 'UserType',
           \'entity.name.type.enum.cpp': 'UserType',
           \'entity.name.type.template.cpp': 'UserType',
           \'variable.other.cpp': 'Variable',
           \'variable.other.enummember.cpp': 'Constant',
           \'variable.other.field.cpp': 'MemberVariable',
           \ }
endfunction

au User lsp_setup call lsp#register_server({
    \ 'name': 'cpp-clangd',
    \ 'whitelist': ['cpp', 'c'],
    \ 'cmd': {server_info->['/usr/local/opt/llvm/bin/clangd',
    \                       '--background-index',
    \                       '--header-insertion=never',
    \                       '--suggest-missing-includes',
    \                      ]},
    \ 'semantic_highlight': s:get_cpp_semantic_highlight_info()
    \ })

au User lsp_setup call lsp#register_server({
    \ 'name': 'python-language-server',
    \ 'whitelist': ['python'],
    \ 'cmd': {server_info->['pyls']},
    \ })

au User lsp_setup call lsp#register_server({
    \ 'name': 'javascript',
    \ 'whitelist': ['javascript', 'typescript'],
    \ 'cmd': {server_info->['node', expand('~/.vim/plugged/javascript-typescript-langserver/lib/language-server-stdio')]},
    \ })


function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=number
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> K <plug>(lsp-hover)
    nmap <buffer> <f2> <plug>(lsp-rename)
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

"}}}

"{{{ Airline options
set laststatus=2
set noshowmode
let g:airline#extensions#disable_rtp_load = 1
"let g:airline_powerline_fonts = 1
let g:airline_left_sep = ''
let g:airline_right_sep = ''

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.whitespace = 'Ξ'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.spell = 'S'
let g:airline_symbols.notexists = '∄'
let g:airline_symbols.readonly = 'RO'

let g:airline#extensions#ycm#enabled = 1
let g:airline#extensions#ycm#error_symbol = '✗'
let g:airline#extensions#ycm#warning_symbol = '⚠'

let g:airline_exclude_preview = 1
let g:airline_exclude_filetypes = ['fuf', 'qf']

"}}} Airline options

"{{{UltiSnips
let g:UltiSnipsSnippetDirectories = ['UltiSnips', 'custom_snippets']
let g:UltiSnipsExpandTrigger = "<c-j>"
"}}}

"{{{ NERDTree
map <F6> :NERDTreeToggle<CR>
augroup myPlugins
    autocmd!
    "Automatically close NERDTree when file is closed
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END
"}}}

"{{{ CtrlP
nnoremap <C-f> :CtrlP .<CR>
let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
let g:ctrlp_map = ''
"}}}

"{{{ delimitMate options
let g:delimitMate_expand_space = 1
let g:delimitMate_expand_cr = 1
" Turn off <S-Tab> mapping since it messes up with YCM
let g:delimitMate_tab2exit = 0
"}}}

"{{{ glsl
autocmd! BufNewFile,BufRead *.vs,*.fs,*.fsh set ft=glsl
"}}}

"}}} Plugins and options

"{{{ Final touches

"let g:solarized_contrast="high"    "default value is normal
let g:solarized_diffmode="high"    "default value is normal
if has("gui_running")
    set background=dark
    colorscheme solarized
    "set guifont=Inconsolata:h16
    set guifont=JetBrains\ Mono:h14
endif

set colorcolumn=120

" Enable doxygen syntax
let g:load_doxygen_syntax = 1

" {{{ Copy Paste
vnoremap <C-y> "+y
nnoremap <C-p> "+p
"inoremap <C-p> <C-r>+
" }}} mapping

" {{{ Grep in projects

function Find(path, ui)
        if a:ui == 0
                let l:search = "<cword>"
                if expand(l:search) == ""
                        echohl WarningMsg
                        echo "No string under cursor"
                        echohl None
                        return
                endif
        else
                let l:search = input("Search for: ")
                if l:search == ""
                        echohl WarningMsg
                        echo "Empty string"
                        echohl None
                        return
                endif
                let l:search = escape(l:search, ' \"')
        endif
        execute "grep " . l:search . " " . a:path
endfunction

function FindInProject(ui)
        let l:project_path = expand("%:h") . "/*"
        call Find(l:project_path, a:ui)
endfunction

function FindInSparse(ui)
        let l:path = expand("%:h:h") . "/*"
        call Find(l:path, a:ui)
endfunction

nmap <F12> :!p4 edit %<CR>
nmap <F2> :call FindInProject(0)<CR>
nmap <S-F2> :call FindInProject(1)<CR>
nmap <F3> :call FindInSparse(0)<CR>
nmap <S-F3> :call FindInSparse(1)<CR>

"}}} grep

"Disable binary search in tag files till the root of error is discovered
set notagbsearch

" With this, the gui (gvim) now doesn't have the toolbar, the left
" and right scrollbars and the menu.
" HARDCORE!!!
set guioptions-=T
set guioptions-=l
set guioptions-=L
set guioptions-=r
set guioptions-=R
"set guioptions-=m
"set guioptions-=M

"}}}
