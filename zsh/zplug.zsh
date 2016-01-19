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

_Z_DATA="$HOME/.cache/z-directories-trackfile"
zplug "rupa/z", from:github, as:plugin, of:z.sh

zplug "jamesob/desk", from:github, as:command, of:"desk"

zplug "raylee/tldr", from:github, as:command, of:"tldr"

zplug "junegunn/fzf-bin", as:command, from:gh-r, file:fzf, of:"*linux*amd64*"

# Actually doesn't work :( tested : master/1.3/1.3.1
# zplug "vifon/deer", from:github, at:v1.3.1, of:deer

zplug "zsh-users/zsh-syntax-highlighting", from:github, nice:10

zplug install

zplug load
