#!/usr/bin/env zsh
#
# Sources external zsh plugins. Installation and updates are handled by
# scripts/install-zsh-plugins.sh (run by ./install), never at shell startup.

ZSH_PLUGINS_PATH="$HOME/.cache/zsh-plugins"

# Syntax highlighting. zsh-patina is a compiled binary driving a daemon shared
# by every session, not a sourceable plugin: it is installed by the Brewfile on
# macOS and by the .deb on Debian, so it is absent from install-zsh-plugins.sh.
#
# `activate` forks (~4 ms). zshrc caches that kind of cost away for fzf and
# mise; here it must NOT be cached. That call is what starts the daemon, and
# the script it prints carries the binary version the daemon checks on every
# request. A cached copy would leave the daemon unstarted -- and the emitted
# script returns silently when its socket is missing, so highlighting would be
# dead with nothing on stderr to say so.
if command -v zsh-patina >/dev/null 2>&1; then
    eval "$(zsh-patina activate)"
fi

# Fish shell-like fast/unobtrusive autosuggestions for zsh
if [[ -f "$ZSH_PLUGINS_PATH/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$ZSH_PLUGINS_PATH/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Desktop notifications for long-running commands are handled by the terminal
# itself (see notify-on-command-finish in ghostty/config), not by a plugin.

# Pure prompt
if [[ -d "$ZSH_PLUGINS_PATH/pure/symlinks" ]]; then
    fpath=("$ZSH_PLUGINS_PATH/pure/symlinks" $fpath)
    autoload -U promptinit; promptinit
    prompt pure
fi
