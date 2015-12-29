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

if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
    set fileencodings=utf-8,latin1
endif

" Switch syntax highlighting on, when the terminal has colors
if &t_Co > 2 || has("gui_running")
    syntax on
    set hlsearch
endif

set nocompatible         " Use Vim defaults (much better!)
set bs=indent,eol,start  " allow backspacing over everything in insert mode
set viminfo='20,\"50     " read/write a .viminfo file, don't store more than 50 lines of registers
set history=50           " keep 50 lines of command line history
set mouse=a              " enable mouse
set makeprg=synmake      " use Synopsys synmake as default make
set ruler                " show the cursor position all the time
set incsearch            " enable search as you type
set noerrorbells         " don't beep on errors (seems to be not enought)
set visualbell           " switch to blink-screen, to disable beep
set t_vb=                " switch off that blink-screen too :)
set completeopt-=preview " Turn off preview window on completions

" Change default grep command to ignore errors
set grepprg=grep\ -ns\ $*

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

    " Automatically remove trailing spaces and dos-style endlines
    autocmd BufWritePre,FileWritePre * silent! set ff=unix | silent! %s/\s\+$//

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

let s:exts = {'h': ['c', 'cc', 'cpp', 'cxx'], 'c': ['h', 'hpp', 'hxx'], 'hpp': ['cpp', 'cxx', 'cc', 'c'], 'cpp': ['hpp', 'hxx', 'h'], 'hxx': ['cxx', 'cpp', 'cc', 'c'], 'cxx': ['hxx', 'hpp', 'h'], 'cc': ['hpp', 'hxx', 'h']}

function s:FindCorrespondingFile()
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
    exec "edit " . found_file
    try
        if cw != ""
            call search('\<' . cw . '\>')
            normal zz
        endif
    catch
        return
    endtry
endfunction

nnoremap gc :call <SID>FindCorrespondingFile()<CR>

" }}}

"{{{ Plugins and options

"{{{ Memory Usage (this section might return)

function! s:PrintMemoryUsage(message, mem)
    let s:mb = a:mem / 1024.0
    let s:gb = s:mb / 1024.0
    echo printf("%s: %s Kb, or %.1f Mb, or %.2f Gb", a:message, a:mem, s:mb, s:gb)
endfunction

function! s:TotalMemoryUsage()
    let s:mem = system("ps -u $USER -o rss,comm | grep 'orig_vim\\\|python'| awk '{sum += $1} END {print sum}'")
    return s:mem[0:-2]
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
    echo "Your Vims are using " . s:total_vim_memory[0:-2] . "Kb of RAM in summary, which is far beyond acceptable limits."
    echo "Turning Off YouCompleteMe plugin."
    echo "Use :ReportMemory and :ReportTotalMemory commands to find out guilty Vim."
    echohl Normal
    let g:loaded_youcompleteme = 1
endif

"}}}

"{{{ Insert $VIM/plugins directory into rtp,
"    after $HOME/.vim entry, which is first one by default
let s:rtp_list = split(&rtp, ',')
call insert(s:rtp_list, $VIM . '/plugins', 1)
execute 'set rtp=' . join(s:rtp_list, ',')
"}}}

"{{{ Vundle options
set nocompatible
filetype off

"Set rtp for Vundle
execute "set rtp+=" . $VIM . "/plugins/bundle/Vundle.vim"
call vundle#begin($VIM . "/plugins/bundle")

Plugin 'gmarik/Vundle.vim'

Plugin 'Valloric/YouCompleteMe'
Plugin 'bling/vim-airline'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets'
Plugin 'scrooloose/syntastic'
Plugin 'scrooloose/nerdtree'
Plugin 'vim-scripts/L9'
Plugin 'vim-scripts/FuzzyFinder'
Plugin 'Raimondi/delimitMate'
Plugin 'altercation/vim-colors-solarized'

call vundle#end()

filetype plugin indent on
"}}} Vundle options

"{{{ YCM options
let g:ycm_path_to_python_interpreter = '/depot/Python-2.7.2/bin/python'
let g:ycm_confirm_extra_conf = 0
let g:ycm_global_ycm_extra_conf = $VIM . '/ycm_extra_conf.py'
let g:ycm_goto_buffer_command = 'new-or-existing-tab'
nnoremap gD :YcmCompleter GoTo<CR>
nnoremap gd :YcmCompleter GoToImprecise<CR>
nnoremap gh :YcmCompleter GetDocQuick<CR>
nnoremap <expr> gf (match(getline('.'), '^\s*#\s*include') != -1) ? ':YcmCompleter GoToInclude<CR>' : '<c-w>gf'
"}}} YCM options

"{{{ Airline options
set laststatus=2
set noshowmode
let g:airline_powerline_fonts = 1
let g:airline_exclude_preview = 1
let g:airline_exclude_filetypes = ['fuf', 'qf']
"let g:airline#extensions#bufferline#overwrite_variables = 0
"let g:airline#extensions#tabline#enabled = 1

"{{{ Add fonts to make Airline look pretty
let s:utils_path = fnamemodify($VIM, ":h") . "/utils"
if findfile("PowerlineSymbols.otf", $HOME . "/.fonts") == ""
    echo "Run the following commands to fix ugly symbols in your new statusline plugin:"
    echo "mkdir ~/.fonts"
    echo "cp " . s:utils_path . "/fontconfig/PowerlineSymbols.otf ~/.fonts/"
    echo "fc-cache -f ~/.fonts"
    echo "cp " . s:utils_path . "/fontconfig/10-powerline-symbols.conf ~/.fontconfig/"
endif
"}}}

"}}} Airline options

"{{{UltiSnips
let g:UltiSnipsSnippetDirectories = [$VIM . '/plugins/custom_snippets', 'UltiSnips']
let g:UltiSnipsExpandTrigger = "<c-j>"
"}}}

"{{{ Syntastic options
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '⚠'
let g:syntastic_always_populate_loc_list = 1
"Config file for verilator
let g:syntastic_verilog_config_file = '.config'
"}}}

"{{{ NERDTree
map <F6> :NERDTreeToggle<CR>
augroup myPlugins
    autocmd!
    "Automatically close NERDTree when file is closed
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
augroup END
"}}}

"{{{ Fuzzy Finder
nnoremap <C-f> :FufFile src/**/<CR>
" Add include and export dirs to excluded
let g:fuf_file_exclude = '\v\~$|\.(o|exe|dll|bak|orig|sw[po])$|(^|[/\\])\.(hg|git|bzr)($|[/\\])|/(include|export)/'
"}}}

"{{{ delimitMate options
let g:delimitMate_expand_space = 1
let g:delimitMate_expand_cr = 1
" Turn off <S-Tab> mapping since it mess up with YCM
let g:delimitMate_tab2exit = 0
"}}}

"}}} Plugins and options

"{{{ Final touches

"let g:solarized_contrast="high"    "default value is normal
let g:solarized_diffmode="high"    "default value is normal
set background=dark
colorscheme solarized

set guifont=Inconsolata\ 16

set rtp+=/remote/custom1/algo/davits/tools/p4vim
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

function Find(path, ui, flags)
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
        execute "grep " . l:search . " " . a:path . " " . a:flags
endfunction

function FindInProject(ui)
        let l:project_path = expand("%:h") . "/*"
        call Find(l:project_path, a:ui, "-I")
endfunction

function FindInSparse(ui)
        let l:path = expand("%:h:h") . "/*"
        call Find(l:path, a:ui, "-rI")
endfunction

nmap <F12> :!p4 edit %<CR>
nmap <F2> :call FindInProject(0)<CR>
nmap <S-F2> :call FindInProject(1)<CR>
nmap <F3> :call FindInSparse(0)<CR>
nmap <S-F3> :call FindInSparse(1)<CR>
nmap <F5> :make shlib-debug -j localhost:8<CR>
nmap <S-F5> :make install-debug -j localhost:8<CR>

"}}} grep

"}}}
