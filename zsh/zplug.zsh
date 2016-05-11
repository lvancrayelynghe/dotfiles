export ZPLUG_HOME=~/.zplug
if [ ! -f ~/.zplug/zplug ]; then
    echo "$fg_bold[yellow]Installing zplug...$reset_color"
    mkdir -p ~/.zplug
    git clone https://github.com/zplug/zplug $ZPLUG_HOME
    source $ZPLUG_HOME/init.zsh
    chmod u+x ~/.zplug/zplug
    echo "$fg_bold[yellow]Done ! $reset_color\n"
    source ~/.zplug/zplug
    zplug update --self
else
    source ~/.zplug/zplug
fi

ZPLUG_VERSION=`zplug --version`

if [[ $ZPLUG_VERSION == 2* ]]; then
    zplug "b4b4r07/zplug", from:github
    zplug "rimraf/k", from:github, as:plugin
    zplug "jamesob/desk", from:github, as:command, use:"desk"
    zplug "raylee/tldr", from:github, as:command, use:"tldr"
    zplug "junegunn/fzf-bin", as:command, from:gh-r, rename-to:fzf, use:"*linux*amd64*"
    zplug "Russell91/sshrc", from:github, as:command, use:"sshrc"
    zplug "ymattw/cdiff", from:github, as:command, use:"cdiff.py", rename-to:"cdiff", at:0.9.8
    zplug "0xAX/git-cheat", from:github, as:command, use:"git-cheat"
    zplug "knu/z", from:github, as:plugin, use:z.sh, nice:10
    zplug "zsh-users/zsh-syntax-highlighting", from:github, nice:10
else
    zplug "b4b4r07/zplug", from:github
    zplug "rimraf/k", from:github, as:plugin
    zplug "jamesob/desk", from:github, as:command, of:"desk"
    zplug "raylee/tldr", from:github, as:command, of:"tldr"
    zplug "junegunn/fzf-bin", as:command, from:gh-r, file:fzf, of:"*linux*amd64*"
    zplug "Russell91/sshrc", from:github, as:command, of:"sshrc"
    zplug "ymattw/cdiff", from:github, as:command, of:"cdiff.py", file:"cdiff", at:0.9.8
    zplug "0xAX/git-cheat", from:github, as:command, of:"git-cheat"
    zplug "knu/z", from:github, as:plugin, of:z.sh, nice:10
    zplug "zsh-users/zsh-syntax-highlighting", from:github, nice:10
fi

_Z_DATA="$HOME/.cache/z-directories-trackfile" # Source after compinit to enable completion

if ! zplug check; then
    zplug install
fi

zplug load
