""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General                                                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader=":"                " Force default mapleader
set nocompatible                 " Get rid of Vi compatibility mode. SET FIRST!
set encoding=utf-8 nobomb        " Use UTF-8 without BOM
set mouse=v                      " Enable mouse in visual mode
set clipboard=unnamed            " Use the OS clipboard by default (on versions compiled with `+clipboard`)
set wildmenu                     " Enhance command-line completion
set nobackup                     " No backup
set nowritebackup                " No backup
set noswapfile                   " No swapfile
set autowrite                    " Automatically :write before running commands
set viminfo+=n~/.vim/viminfo     " Move viminfo path

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Text Formatting/Layout                                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set backspace=indent,eol,start " make backspace delete lots of things
set autoindent                 " auto-indent
set tabstop=4                  " tab spacing
set softtabstop=4              " unify
set shiftwidth=4               " indent/outdent by X columns
set shiftround                 " always indent/outdent to the nearest tabstop
set expandtab                  " use spaces instead of tabs
set smartindent                " automatically insert one extra level of indentation
set smarttab                   " use tabs at the start of a line, spaces elsewhere
set nowrap                     " don't wrap text

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim UI                                                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax enable             " enable syntax highlighting (previously syntax on)
set number                " show line numbers
set numberwidth=5         " make the number gutter X characters wide
set cursorline            " highlight current line
set laststatus=2          " last window always has a statusline
set nohlsearch            " Don't continue to highlight searched phrases.
set incsearch             " But do highlight as you type your search.
set ignorecase            " Make searches case-insensitive.
set ruler                 " Always show info along bottom.
set showmatch             " Show matching brackets
set showmode              " Show the current mode
set scrolloff=3           " Start scrolling three lines before horizontal border of window.
set sidescrolloff=3       " Start scrolling three columns before vertical border of window.
set statusline=%<%f\%h%m%r%=%-20.(line=%l\ \ col=%c%V\ \ totlin=%L%)\ \ \%h%m%r%=%-40(bytval=0x%B,%n%Y%)\%P

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Special functions                                                          "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Trim extra whitespace
function! StripExtraWhiteSpace()
    let l = line(".")
    let c = col(".")
    %s/\s\+$//e
    call cursor(l, c)
endfunction
noremap <leader>ss :call StripExtraWhiteSpace()<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Custom keymaps                                                             "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle lines number
nmap <F2> :set number! number?<CR>
imap <F2> <C-O><F2>
set showmode

" Toggle paste mode
nmap <F3> :set invpaste paste?<CR>
set pastetoggle=<F3>
set showmode

" File explorer
nmap <F4> :Explore<CR>
set showmode
