#!/usr/bin/env zsh
#
# Sources external zsh plugins. Installation and updates are handled by
# scripts/install-zsh-plugins.sh (run by ./install), never at shell startup.

ZSH_PLUGINS_PATH="$HOME/.cache/zsh-plugins"

# Syntax highlighting. zsh-patina is a compiled binary driving a daemon shared
# by every session, not a sourceable plugin: it is installed by mise's macOS
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

# Fish shell-like fast/unobtrusive autosuggestions for zsh.
#
# MANUAL_REBIND stops the plugin re-binding its widgets from `precmd`. It was
# rebinding 387 of them on every single prompt here: ~8.9 ms, 44% of
# `command_lag` (20.3 -> 11.4 ms measured A/B, 3 rounds). Upstream rebinds
# because zsh-syntax-highlighting wrapped those widgets and broke otherwise --
# zsh-patina hooks `line-pre-redraw` instead of wrapping anything, so that
# reason no longer applies to this config.
#
# Nothing is lost: the single binding pass runs from the *first* precmd, after
# all of zshrc, so the widgets fzf/zoxide/mise install are already there when
# it happens. Verified -- same 387 widgets bound with and without, including
# fzf-history-widget, and the ghost text still appears. Only a plugin wrapping
# autosuggest widgets *after* the first prompt would need the rebind loop
# back, so re-check this if lazily-loaded widgets ever appear here.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
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
