#!/usr/bin/env zsh

# Keeps track of the last used working directory and automatically jumps
# into it for new shells.

# Flag indicating if we've previously jumped to last directory.
typeset -g ZSH_LAST_WORKING_DIRECTORY
typeset -g _lwd_cache_file="$HOME/.cache/last-working-dir"

# Update the cache once the directory changes (registered as a hook so other
# tools using chpwd — zoxide, direnv, terminal integrations — keep working).
autoload -Uz add-zsh-hook
function _lwd_save() {
    # Use >| in case noclobber is set to avoid "file exists" error
    pwd >| "$_lwd_cache_file"
}
add-zsh-hook chpwd _lwd_save

# Changes directory to the last working directory.
function lwd() {
    [[ -r "$_lwd_cache_file" ]] && cd "$(<"$_lwd_cache_file")"
}

# Automatically jump to last working directory unless this isn't the first time
# this plugin has been loaded, and only when starting from $HOME.
if [[ -z "$ZSH_LAST_WORKING_DIRECTORY" ]]; then
    [[ "$PWD" == "$HOME" ]] && lwd 2>/dev/null
    ZSH_LAST_WORKING_DIRECTORY=1
fi
