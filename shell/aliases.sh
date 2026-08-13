# Shared aliases for bash AND zsh (sourced by bash/bashrc and zsh/zshrc).
# Keep this file POSIX-friendly: no zsh-only syntax (global/suffix aliases
# live in zsh/aliases.zsh).
#
# This is the entry point: it holds the general-purpose aliases, then sources
# the per-topic files at the bottom. Everything callers need is still a single
# `source shell/aliases.sh`. New topic file? Add it to the list down there and
# to cheat-sheet() in zsh/functions.zsh, which reads these files to build the
# help output.

# Directories navigation (zsh uses auto_cd + global aliases instead)
if [ -n "$BASH_VERSION" ]; then
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    alias ......='cd ../../../../..'
    alias .......='cd ../../../../../..'
fi

# Directories working (leading space keeps them out of history)
alias pwd=' pwd'
alias cd=' cd'
alias cdg=' cd "$(git rev-parse --show-toplevel)"' ## git root

# Listing
alias l='ls -lh --group-directories-first'
alias ll='ls -lhA --group-directories-first'
alias llm='ls -lhAt --group-directories-first' ## "m" for sort by last modified date
alias llc='ls -lhAU --group-directories-first' ## "c" for sort by creation date
alias lls='ls -lhAS --group-directories-first' ## "s" for sort by size
alias k='eza -abghHlS --group-directories-first'
alias kk='eza -abghHlS --group-directories-first --git'
alias kt='eza -hlT --group-directories-first'
alias ktt='eza -hlT -L2 --group-directories-first'
alias kttt='eza -hlT -L3 --group-directories-first'

# 1 letter commands shortcuts
alias c=" clear && printf '\e[3J'"
alias p=' dirs -v | head -10' ## most used dirs for current session
alias x=' exit'
alias h='history'
alias j='jobs'
alias t='tmux'
alias v='open-with-vim'
alias e='open-with-vim'
alias s='open-with-sublime-text'
alias n='nano'
alias g='git'

# Others commands shortcuts
alias k9='kill -9'
alias rd='rmdir'
alias md='mkdir -p'
alias mcd='mkdir-cd'
alias mkcd='mkdir-cd'
alias rmf='rm -rf'
alias rmrf='rm -rf'
alias cpr='cp -r'
alias bak='backup-file'
alias psy='psysh'
alias run='make'
alias phpl='php -l'
alias tailf='tail -f'
alias less='less -r'
alias whence='type -a'
alias grep='grep --color=auto'
alias vgrep='grep -v --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

alias sudo='sudo ' ## Allow aliases to be sudo'ed
alias watch='watch ' ## Allow aliases to be watched

# Search & find
alias ss='sift -n' ## with sift
alias rg='rg -S' ## smart-case ripgrep
alias ff='find . -type f -iname ' ## insensitive filename
alias fr='find-and-replace' ## find and replace in current dir

# Files permissions (BSD chmod requires options before the mode)
alias 400='chmod -R 400'
alias 600='chmod -R 600'
alias 640='chmod -R 640'
alias 644='chmod -R 644'
alias 755='chmod -R 755'
alias 775='chmod -R 775'
alias 777='chmod -R 777'
alias www='chown -R www-data:www-data .'
alias mx='chmod u+x'

# Datetime helpers
alias week='date +%V'
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Because Oo
alias tableflip="echo '(ノಠ益ಠ)ノ彡┻━┻'" ## see https://gist.github.com/endolith/157796

# >>> plumbing: everything below is hidden from cheat-sheet()
#
# Some of the names below were plain aliases before: drop them so re-sourcing in
# an older live shell doesn't abort on "defining function based on alias". Must
# stay ahead of both the disk usage block and the sourcing block.
unalias pubkey du du0 du1 du1s df 2>/dev/null || true

# Disk usage, through dust and duf. Same commands on both platforms, so no
# $OSTYPE branch and no dependency on brew coreutils.
alias du='dust'
alias du0='dust -d 0' ## total only
alias du1s='dust -d 1' ## one level, by size (dust always sorts by size)
alias df='duf'

# dust has no name sort, so this one keeps plain du, which takes -d on BSD too
du1() { command du -hd1 "$@" | sort -k2; } ## one level, by name

# Per-topic files
_ALIASES_DIR="${DOTFILES_PATH:-$HOME/.dotfiles/public}/shell"
. "$_ALIASES_DIR/aliases-git.sh"
. "$_ALIASES_DIR/aliases-docker.sh"
. "$_ALIASES_DIR/aliases-dev.sh"
. "$_ALIASES_DIR/aliases-net.sh"

# The OS file comes last on purpose: on macOS it replaces the generic grep
# aliases above with the GNU ones.
if [[ "$OSTYPE" == darwin* ]]; then
    . "$_ALIASES_DIR/aliases-macos.sh"
else
    . "$_ALIASES_DIR/aliases-linux.sh"
fi
unset _ALIASES_DIR
