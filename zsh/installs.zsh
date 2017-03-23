#!/usr/bin/env zsh

mkdir -p "$BIN_PATH"
mkdir -p "$HOME/.cache/zsh-plugins"

# Remove zplug, not used anymore
if [ -d ~/.zplug ]; then
    rm -rf ~/.zplug
fi


# A tool like grep, optimized for programmers
if [[ ! -e "${BIN_PATH}/ack" ]]; then
    curl -s http://beyondgrep.com/ack-2.14-single-file > "${BIN_PATH}/ack" && chmod 0755 "${BIN_PATH}/ack"
fi


# A collection of simplified and community-driven man pages
if [[ ! -e "${BIN_PATH}/tldr" ]]; then
    curl -s https://raw.githubusercontent.com/raylee/tldr/master/tldr > "${BIN_PATH}/tldr" && chmod 0755 "${BIN_PATH}/tldr"
fi


# sshrc works just like ssh, but it also sources the ~/.sshrc on your local computer after logging in remotely
if [[ ! -e "${BIN_PATH}/sshrc" ]]; then
    curl -s https://raw.githubusercontent.com/Russell91/sshrc/master/sshrc > "${BIN_PATH}/sshrc" && chmod 0755 "${BIN_PATH}/sshrc"
fi


# Term based tool to view colored, incremental diff in a Git/Mercurial/Svn workspace or from stdin, with side by side and auto pager support
if [[ ! -e "${BIN_PATH}/cdiff" ]]; then
    curl -s https://raw.githubusercontent.com/ymattw/cdiff/0.9.8/cdiff.py > "${BIN_PATH}/cdiff" && chmod 0755 "${BIN_PATH}/cdiff"
fi


# git-cheat is a dependency free git helper in your command-line
if [[ ! -e "${BIN_PATH}/git-cheat" ]]; then
    curl -s https://raw.githubusercontent.com/0xAX/git-cheat/master/git-cheat > "${BIN_PATH}/git-cheat" && chmod 0755 "${BIN_PATH}/git-cheat"
fi


# Lightweight workspace manager for the shell
if [[ ! -f ~/.cache/zsh-plugins/desk/desk ]]; then
    mkdir -p ~/.cache/zsh-plugins/desk
    git clone https://github.com/jamesob/desk.git ~/.cache/zsh-plugins/desk
    cp ~/.cache/zsh-plugins/desk/desk "${BIN_PATH}/desk"
fi
fpath=(~/.cache/zsh-plugins/desk/shell_plugins/zsh $fpath)


# A plugin to make directory listings more readable
if [[ ! -f ~/.cache/zsh-plugins/k/k.sh ]]; then
    mkdir -p ~/.cache/zsh-plugins/k
    git clone https://github.com/supercrabtree/k.git ~/.cache/zsh-plugins/k
fi
[[ -n "$DEBUG" ]] && trace-time "Loading external plugin k"
source ~/.cache/zsh-plugins/k/k.sh


# A general-purpose command-line fuzzy finder
if [[ ! -f ~/.fzf.zsh ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.cache/zsh-plugins/fzf
    ~/.cache/zsh-plugins/fzf/install --no-key-bindings --no-update-rc --completion
fi
[[ -n "$DEBUG" ]] && trace-time "Loading external plugin fzf"
source ~/.fzf.zsh


# Tracks your most used directories, based on "frecency"
if [[ ! -f ~/.cache/zsh-plugins/z/z.sh ]]; then
    mkdir -p ~/.cache/zsh-plugins/z
    git clone https://github.com/rupa/z.git ~/.cache/zsh-plugins/z
fi
[[ -n "$DEBUG" ]] && trace-time "Loading external plugin z"
source ~/.cache/zsh-plugins/z/z.sh
_Z_DATA="$HOME/.cache/z-directories-trackfile" # Source after compinit to enable completion


# Fish shell-like like syntax highlighting for Zsh
if [[ ! -f ~/.cache/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    mkdir -p ~/.cache/zsh-plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.cache/zsh-plugins/zsh-syntax-highlighting
fi
[[ -n "$DEBUG" ]] && trace-time "Loading external plugin zsh-syntax-highlighting"
source ~/.cache/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Fish shell-like fast/unobtrusive autosuggestions for zsh.
if [[ ! -f ~/.cache/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    mkdir -p ~/.cache/zsh-plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.cache/zsh-plugins/zsh-autosuggestions
fi
[[ -n "$DEBUG" ]] && trace-time "Loading external plugin zsh-autosuggestions"
source ~/.cache/zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh


# Desktop notifications for long-running commands in zsh.
if [[ ! -f ~/.cache/zsh-plugins/zsh-notify/notify.plugin.zsh ]]; then
    mkdir -p ~/.cache/zsh-plugins/zsh-notify
    git clone https://github.com/marzocchi/zsh-notify.git ~/.cache/zsh-plugins/zsh-notify
fi
[[ -n "$DEBUG" ]] && trace-time "Loading external plugin zsh-notify"
source ~/.cache/zsh-plugins/zsh-notify/notify.plugin.zsh
zstyle ':notify:*' command-complete-timeout 10
zstyle ':notify:*' success-title "Command completed successfully"
zstyle ':notify:*' error-title "Command completed with warning"
