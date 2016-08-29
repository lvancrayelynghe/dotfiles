mkdir -p "$HOME/bin"
mkdir -p "$HOME/.cache/zsh-plugins"

# Remove zplug, not used anymore
if [ -d ~/.zplug ]; then
    rm -rf ~/.zplug
fi


# A tool like grep, optimized for programmers
if [[ ! -e ~/bin/ack ]]; then
    curl -s http://beyondgrep.com/ack-2.14-single-file > ~/bin/ack && chmod 0755 ~/bin/ack
fi


# A collection of simplified and community-driven man pages
if [[ ! -e ~/bin/tldr ]]; then
    curl -s https://raw.githubusercontent.com/raylee/tldr/master/tldr > ~/bin/tldr && chmod 0755 ~/bin/tldr
fi


# sshrc works just like ssh, but it also sources the ~/.sshrc on your local computer after logging in remotely
if [[ ! -e ~/bin/sshrc ]]; then
    curl -s https://raw.githubusercontent.com/Russell91/sshrc/master/sshrc > ~/bin/sshrc && chmod 0755 ~/bin/sshrc
fi


# Term based tool to view colored, incremental diff in a Git/Mercurial/Svn workspace or from stdin, with side by side and auto pager support
if [[ ! -e ~/bin/cdiff ]]; then
    curl -s https://raw.githubusercontent.com/ymattw/cdiff/0.9.8/cdiff.py > ~/bin/cdiff && chmod 0755 ~/bin/cdiff
fi


# git-cheat is a dependency free git helper in your command-line
if [[ ! -e ~/bin/git-cheat ]]; then
    curl -s https://raw.githubusercontent.com/0xAX/git-cheat/master/git-cheat > ~/bin/git-cheat && chmod 0755 ~/bin/git-cheat
fi


# Lightweight workspace manager for the shell
if [[ ! -f ~/.cache/zsh-plugins/desk/desk ]]; then
    mkdir -p ~/.cache/zsh-plugins/desk
    git clone https://github.com/jamesob/desk.git ~/.cache/zsh-plugins/desk
    cp ~/.cache/zsh-plugins/desk/desk ~/bin/desk
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
