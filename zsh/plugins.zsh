#!/usr/bin/env zsh
#
# Sources external zsh plugins. Installation and updates are handled by
# scripts/install-zsh-plugins.sh (run by ./install), never at shell startup.

ZSH_PLUGINS_PATH="$HOME/.cache/zsh-plugins"

# Fish shell-like syntax highlighting for zsh
if [[ -f "$ZSH_PLUGINS_PATH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    [[ -n "$DEBUG" ]] && trace-time "Loading external plugin zsh-syntax-highlighting"
    source "$ZSH_PLUGINS_PATH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Fish shell-like fast/unobtrusive autosuggestions for zsh
if [[ -f "$ZSH_PLUGINS_PATH/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    [[ -n "$DEBUG" ]] && trace-time "Loading external plugin zsh-autosuggestions"
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
