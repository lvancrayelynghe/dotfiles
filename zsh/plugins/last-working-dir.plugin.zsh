#!/usr/bin/env zsh

# Keeps track of the last used working directory and automatically jumps
# into it for new shells.

# Flag indicating if we've previously jumped to last directory.
typeset -g ZSH_LAST_WORKING_DIRECTORY
cache_file="$HOME/.cache/last-working-dir"
touch $cache_file

# Updates the last directory once directory is changed.
function chpwd() {
  # Use >| in case noclobber is set to avoid "file exists" error
	pwd >| "$cache_file"
}

# Changes directory to the last working directory.
function lwd() {
	if [[ $(pwd) = "$HOME" ]]; then
		[[ ! -r "$cache_file" ]] || cd "$(cat "$cache_file")"
	fi
}

# Automatically jump to last working directory unless this isn't the first time
# this plugin has been loaded.
if [[ -z "$ZSH_LAST_WORKING_DIRECTORY" ]]; then
	lwd 2>/dev/null && ZSH_LAST_WORKING_DIRECTORY=1 || true
fi
