if [ ! -f ~/.zplug/zplug ]; then
    echo "$fg_bold[yellow]Installing zplug...$reset_color"
    mkdir -p ~/.zplug
    wget -q https://git.io/zplug -O ~/.zplug/zplug
    chmod u+x ~/.zplug/zplug
    echo "$fg_bold[yellow]Done ! $reset_color\n"
    source ~/.zplug/zplug
    zplug update --self
else
    source ~/.zplug/zplug
fi

zplug "b4b4r07/zplug", from:github

zplug "rimraf/k", from:github, as:plugin

zplug "jamesob/desk", from:github, as:command, of:"desk"

zplug "raylee/tldr", from:github, as:command, of:"tldr"

zplug "junegunn/fzf-bin", as:command, from:gh-r, file:fzf, of:"*linux*amd64*"

zplug "Russell91/sshrc", from:github, as:command, of:"sshrc"

zplug "ymattw/cdiff", from:github, as:command, of:"cdiff.py", file:"cdiff", at:0.9.8

# Actually doesn't work :( tested : master/1.3/1.3.1
# zplug "vifon/deer", from:github, at:v1.3.1, of:deer

# Source after compinit to enable completion
_Z_DATA="$HOME/.cache/z-directories-trackfile"
zplug "knu/z", from:github, as:plugin, of:z.sh, nice:10

zplug "zsh-users/zsh-syntax-highlighting", from:github, nice:10

zplug install

zplug load
