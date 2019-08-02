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
set fileformats=unix     " We are working only with linux style line endings, will highlight otherwise
set fileformat=unix      " Set buffer line endings style to linux

" Change default grep command to ignore errors
set grepprg=ag\ --nogroup\ --nocolor

"Since Tab and trailing spaces are prohibited by our coding style
"force vim to display them to make more notable to users
set listchars=tab:>-,trail:_
set list

"}}}

"{{{ Indenting options and autocommands

" Tabulation and indenting options according to CD coding style
set expandtab
set cindent
set shiftwidth=4
set tabstop=4
set softtabstop=4
"Settings for C++ files are set by below autocmd

augroup system_vimrc

    autocmd!

    "Set tab to 4 if Tcl or vim file is opened
    autocmd FileType tcl,vim set shiftwidth=4 tabstop=4 softtabstop=4

    "Switch back to 8 for cpp files
    autocmd FileType c,cpp set shiftwidth=8 tabstop=8 softtabstop=8

    " Automatically remove trailing spaces
    autocmd BufWritePre,FileWritePre * silent! %s/\s\+$//

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
    exec "nnoremap <A-" . i . "> <Esc>" . i . "gt"
    let i += 1
endwhile
"}}}

"}}} Movement mapping

" {{{ Functionality to jump between corresponding C++ files

let s:exts = {
             \ 'h'  : ['c', 'cc', 'cpp', 'cxx'],
             \ 'c'  : ['h', 'hpp', 'hxx'],
             \ 'hpp': ['cpp', 'cxx', 'cc', 'c'],
             \ 'cpp': ['hpp', 'hxx', 'h'],
             \ 'hxx': ['cxx', 'cpp', 'cc', 'c'],
             \ 'cxx': ['hxx', 'hpp', 'h'],
             \ 'cc' : ['hpp', 'hxx', 'h']
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
    if !has_key(s:exts, cfe)
        echohl ErrorMsg
        echo "Only " . string(sort(keys(s:exts))) . " files are supported."
        echohl None
        return
    endif
    let found_file = ""
    for ext in s:exts[cfe]
        let fn = expand("%:r") . "." . ext
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

map <C-T> :pyf /opt/llvm/share/clang/clang-format.py<cr>

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

function! s:PrintMemoryUsage(message, mem)
    let s:mb = a:mem / 1024.0
    let s:gb = s:mb / 1024.0
    echo printf("%s: %.2fGb (%.1fMb or %sKb)", a:message, s:gb, s:mb, a:mem)
endfunction

function! s:TotalMemoryUsage()
    let s:mem = system("ps -u $USER -o rss,comm | \\grep 'vim\\\|python'| awk '{sum += $1} END {print sum}'")
    " Remove newlines at the end.
    let s:mem = substitute(s:mem, '\n\+$', '', '')
    return s:mem
endfunction

function! s:SelfMemoryUsage()
    let s:vim_pid = getpid()
    let s:vim_mem = system("ps -p " . s:vim_pid . " -o rss=")
    let s:ycm_mem = 0
    try
        let s:ycm_pid = youcompleteme#ServerPid()
        let s:ycm_mem = system("ps -p " . s:ycm_pid . " -o rss=")
    catch
    endtry
    return s:vim_mem + s:ycm_mem
endfunction

command! ReportMemory call s:PrintMemoryUsage("Memory used by this Vim", s:SelfMemoryUsage())
command! ReportTotalMemory call s:PrintMemoryUsage("Total memory usage by Vims", s:TotalMemoryUsage())

let s:total_vim_memory = s:TotalMemoryUsage()
if s:total_vim_memory > 4000000
    echohl ErrorMsg
    echo "Your Vims are already using " . s:total_vim_memory . "Kb of RAM in summary, which is far beyond acceptable limits."
    echo "Turning Off YouCompleteMe plugin."
    echo "Use :ReportMemory and :ReportTotalMemory commands to find out guilty Vim."
    echohl Normal
    let g:loaded_youcompleteme = 1
endif

"}}}

"{{{ vim-plug options

call plug#begin('~/.vim/plugged')

Plug 'davits/YouCompleteMe'
Plug 'davits/DyeVim'

"Plug 'vim-airline/vim-airline'
"Plug 'vim-airline/vim-airline-themes'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' }
Plug 'Raimondi/delimitMate'
Plug 'altercation/vim-colors-solarized'
Plug 'davits/autohighlight'
Plug 'tpope/vim-fugitive'

call plug#end()

"}}} vim-plug options

"{{{ YCM options
let g:ycm_confirm_extra_conf = 0
let g:ycm_global_ycm_extra_conf = '~/.vim/ycm_extra_conf.py'
let g:ycm_goto_buffer_command = 'new-or-existing-tab'
nnoremap gD :YcmCompleter GoTo<CR>
nnoremap gd :YcmCompleter GoToImprecise<CR>
nnoremap gh :YcmCompleter GetDocQuick<CR>
nnoremap <expr> gf (match(getline('.'), '^\s*#\s*include') != -1) ? ':YcmCompleter GoToInclude<CR>' : '<c-w>gf'

function! s:ShowDoc()
    if !has("gui_running") || !has("overlay")
        return
    endif
    let s:line = line('.')
    let s:column = col('.')
    let s:doc = pyeval('ycm_state.GetDoc(' . s:line . ', ' . s:column . ')')
    if s:doc != ''
        call overlayshow(s:line, s:column, [ s:doc ])
    endif
endfunction

augroup ycm_options
    autocmd!
    autocmd CursorMoved * call overlayclose()
    autocmd InsertEnter * call overlayclose()
augroup END

nnoremap <silent> K :call <SID>ShowDoc()<CR>
"}}} YCM options

"{{{ DyeVim options
let g:dyevim_timeout=30
"}}}

"{{{ Airline options
set laststatus=2
set noshowmode
let g:airline#extensions#disable_rtp_load = 1
"let g:airline_powerline_fonts = 1
let g:airline_left_sep = '▶'
let g:airline_right_sep = '◀'

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

"{{{ Syntastic options
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'
let g:syntastic_always_populate_loc_list = 1
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
nnoremap <C-f> :CtrlP src/<CR>
let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
let g:ctrlp_map = ''
"}}}

"{{{ delimitMate options
let g:delimitMate_expand_space = 1
let g:delimitMate_expand_cr = 1
" Turn off <S-Tab> mapping since it messes up with YCM
let g:delimitMate_tab2exit = 0
"}}}

"}}} Plugins and options

"{{{ Final touches

"let g:solarized_contrast="high"    "default value is normal
let g:solarized_diffmode="high"    "default value is normal
set background=dark
colorscheme solarized

set colorcolumn=80

set guifont=Inconsolata\ 16

" Enable doxygen syntax
"let g:load_doxygen_syntax = 1

" With this, the gui (gvim) now doesn't have the toolbar, the left
" and right scrollbars and the menu.
" HARDCORE!!!
set guioptions-=T
set guioptions-=l
set guioptions-=L
set guioptions-=r
set guioptions-=R
set guioptions-=m
set guioptions-=M

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

"}}}
