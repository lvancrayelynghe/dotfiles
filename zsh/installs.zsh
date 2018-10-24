#!/usr/bin/env zsh

mkdir -p "$BIN_PATH"
mkdir -p "$HOME/.cache/zsh-plugins"

# git-cheat is a dependency free git helper in your command-line
if [[ ! -e "${BIN_PATH}/git-cheat" ]]; then
    curl -s https://raw.githubusercontent.com/0xAX/git-cheat/master/git-cheat > "${BIN_PATH}/git-cheat" && chmod 0755 "${BIN_PATH}/git-cheat"
fi

# lf terminal file manager
if [[ ! -e "/usr/local/bin/lf" ]]; then
    wget -q "https://github.com/gokcehan/lf/releases/download/r4/lf-darwin-amd64.tar.gz" -O /tmp/lf.tar.gz
    (cd /tmp && tar -zxvf /tmp/lf.tar.gz)
    mv /tmp/lf /usr/local/bin
    rm -rf /tmp/lf.tar.gz
fi

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

# Pure Theme
if [[ ! -d ~/.cache/zsh-plugins/pure ]]; then
    mkdir -p ~/.cache/zsh-plugins/pure
    git clone https://github.com/sindresorhus/pure.git ~/.cache/zsh-plugins/pure
    mkdir -p ~/.cache/zsh-plugins/pure/symlinks

    cd ~/.cache/zsh-plugins/pure
    ln -s "$PWD/pure.zsh" "$PWD/symlinks/prompt_pure_setup"
    ln -s "$PWD/async.zsh" "$PWD/symlinks/async"
    cd
fi
fpath=(~/.cache/zsh-plugins/pure/symlinks $fpath)

autoload -U promptinit; promptinit
prompt pure
