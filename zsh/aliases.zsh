#!/usr/bin/env zsh
#
# zsh-only aliases. Everything shared with bash lives in shell/aliases.sh,
# which is sourced before this file.

# Global directories aliases (usable in the middle of a command line)
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -g .......='../../../../../..'

# Global pipe aliases (append to any command: `ls -l L`, `ps aux G nginx`)
alias -g G='| grep'
alias -g N='| grep -v'
alias -g E='| grep-passthru' ## see functions.zsh
alias -g F='| fzf --ansi'
alias -g H='| head'
alias -g T='| tail'
alias -g S='| sort'
alias -g C='| wc -l'
alias -g L="| less"
alias -g X='| xargs'
alias -g XS='| xargs subl'

# Global colouring pipes (highlight lives in functions.zsh)
alias -g HR='| highlight red'
alias -g HG='| highlight green'
alias -g HY='| highlight yellow'
alias -g HB='| highlight blue'
alias -g HC='| highlight cyan'
alias -g HM='| highlight magenta'

# Global copy to clipboard
if [[ "$OSTYPE" == darwin* ]]; then
    alias -g CC='| pbcopy'
else
    alias -g CC='| xclip -selection clipboard'
fi

# Directory stack navigation (see directories.zsh)
alias -- -=' cd -'
alias 1=' cd -'
alias 2=' cd -2'
alias 3=' cd -3'
alias 4=' cd -4'
alias 5=' cd -5'
alias 6=' cd -6'
alias 7=' cd -7'
alias 8=' cd -8'
alias 9=' cd -9'

# Config management
alias zshrc='source ~/.zshrc' ## Reload config
dotfiles() {
    local profile
    git -C "${DOTFILES_PATH}" pull || return
    if [[ -d "${DOTFILES_PATH}/../private/.git" ]]; then
        git -C "${DOTFILES_PATH}/../private" pull || return
    fi
    case "$(uname)" in
        Darwin) profile=macos ;;
        Linux) profile=linux ;;
        *) echo 'dotfiles: unsupported platform' >&2; return 1 ;;
    esac
    mise -C "${DOTFILES_PATH}" -E "$profile" bootstrap --yes || return
    source ~/.zshrc
} ## Pull dotfiles, converge the machine, then reload zsh
alias snippets="cat ${DOTFILES_PATH}/zsh/snippets.zsh | sed -r 's/^function //g' | sed -r 's/^# (.*)/\x1b[32m\x1b[1m# \1\x1b[0m/'"
