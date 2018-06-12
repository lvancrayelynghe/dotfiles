#!/usr/bin/env zsh

## Global aliases only works with ZSH
if [[ "$0" =~ 'zsh' ]]; then
    # Global directories aliases
    alias -g ..='..'
    alias -g ...='../..'
    alias -g ....='../../..'
    alias -g .....='../../../..'
    alias -g ......='../../../../..'
    alias -g .......='../../../../../..'

    # Global commands aliases
    alias -g X='| xargs'
    alias -g G='| grep'
    alias -g N='| grep -v'
    alias -g F='| fzf --ansi'
    alias -g E='| grep-passthru'
    alias -g XS='| xargs subl'
    alias -g HR='| highlight red'
    alias -g HG='| highlight green'
    alias -g HB='| highlight blue'
    alias -g HM='| highlight magenta'
    alias -g HC='| highlight cyan'
    alias -g HY='| highlight yellow'
    alias -g C='| wc -l'
    alias -g S='| sort'
    alias -g H='| head'
    alias -g L="| less"
    alias -g T='| tail'
    alias -g P='| pygmentize -O style=monokai -f console256 -g'
else
    # Directories aliases
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    alias ......='cd ../../../../..'
    alias .......='cd ../../../../../..'
fi

# Directories working
alias pwd=' pwd'
alias cd=' cd'
alias cdg=' cd "$(git rev-parse --show-toplevel)"' ## git root
alias -- -=' cd -'
alias 1=' cd -'
alias 2=' cd -2'
alias 3=' cd -3'
alias 4=' cd -4'
alias 5=' cd -5'
alias 6=' cd -6'
alias 7=' cd -7'
alias 8=' cd -8'
alias 9=' cd -9'

alias l='ls -lh --group-directories-first'
alias ll='ls -lhA --group-directories-first'
alias llm='ls -lhAt --group-directories-first' ## "m" for sort by last modified date
alias llc='ls -lhAU --group-directories-first' ## "c" for sort by creation date
alias lls='ls -lhAS --group-directories-first' ## "s" for sort by size
alias lla='ll-archive' ## "a" for archive
alias k='exa -abghHlS --group-directories-first'
alias kk='exa -abghHlS --group-directories-first --git'

# 1 letter commands shortcuts
alias p=' dirs -v | head -10' ## most used dirs for current session
alias x=' exit'
alias d='desk'
alias h='history'
alias j='jobs'
alias t='tmux'
alias v='open-with-vim'
alias e='open-with-vim'
alias s='open-with-sublime-text'
alias a='open-with-atom'
alias n='nano'
alias g='git'

# Others commands shortcuts
alias dg='desk go'
alias zd='z --del'
alias mu='mutt'
alias mf='mutt -F'
alias k9='kill -9'
alias rd='rmdir'
alias md='mkdir -p'
alias mcd='mkdir-cd'
alias mkcd='mkdir-cd'
alias trm='trash-put'
alias rmf="rm -rf"
alias rmrf="rm -rf"
alias cpr="cp -r"
alias bak='backup-file'
alias psy='psysh'
alias run='make'
alias phpl='php -l'
alias tailf='tail -f'
alias less='less -r'
alias whence='type -a'
alias whereis='whereis'
alias grep='grep --color=auto'
alias vgrep='grep -v --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias zshrc='source ~/.zshrc' ## Reload config
alias dotfiles='(cd ${DOTFILES_PATH} && git pull) ; (cd ${DOTFILES_PATH}/../private && git pull) ; source ~/.zshrc' ## Pull dotfiles from repositories and reload config
alias snippets="cat ${DOTFILES_PATH}/zsh/snippets.zsh | sed -r 's/^function //g' | sed -r 's/^# (.*)/\x1b[32m\x1b[1m# \1\x1b[0m/'"

# System stats
alias free='free -h'
alias ps='ps auxf'

# Search & find
alias sg='grep -rinw "." -e ' ## inside files
alias sa='ack -Hir' ## with ack
alias ss='sift -n' ## with sift
alias rg='rg -S' ## with ripgreprg
alias ff='find . -type f -iname ' ## insensitive filename
alias fr='find-and-replace' ## find and replace in current dir

# Git
alias gcl='git clone --recursive'
alias gcf='git config'
alias gs='git status'
alias gst='git status-short'
alias ga='git add'
alias gaa='git add -A'
alias gl='git log'
alias gls='git log --stat' ## include which files were altered
alias glp='git log -p' ## display the full diff of each commit
alias gll='git pretty-log'
alias gbl='git blame -b -w'
alias gd='git diff'
alias gdw='git diff --word-diff'
alias gdt='git difftool'
alias gw='git whatchanged'
alias gg='git grep -n -C2 -E'
alias gc='git commit -v'
alias gc!='git commit -v --amend'
alias gcu='git reset --soft HEAD~' ## undo commit
alias gcm='git commit -m'
alias gca='git commit -a'
alias gcam='git commit -a -m'
alias gb='git branch'
alias gbm='git branch --merged'
alias gbr='git branch -r'
alias gbu='git remote update origin --prune' ## update remote list
alias gm='git merge'
alias gms='git merge --squash'
alias gmm='git merge -m'
alias gt='git tag'
alias gco='git checkout'
alias gcom='git checkout master'
alias gcop='git checkout preprod'
alias gcor='git checkout recette'
alias gf='git fetch'
alias gfo='git fetch origin'
alias gp='git pull'
alias gpull='git pull'
alias gpush='git push'
alias gpr='git pull --rebase'
alias gsu='git set-upstream'
alias gget='git get'
alias gput='git put'
alias ggp='git get-put'
alias grb='git rebase'
alias gss='git stash save'
alias gsa='git stash apply'
alias gsp='git stash pop'
alias gsl='git stash list'
alias ggc='git gc --aggressive'
alias cgd='cdiff -s -w 0' ## columned & colored git diff
alias cgs='columns-git-show' ## columned & colored git diff

# Docker
alias doi="docker images"
alias dov="docker volume"
alias doe="docker exec"
alias dok="docker kill"
alias dops="docker ps"
alias dorm="docker rm"
alias dormi="docker rmi"

# rsync
alias rsync-copy="rsync -av --progress -h --exclude-from=$HOME/.cvsignore"
alias rsync-move="rsync -av --progress -h --remove-source-files --exclude-from=$HOME/.cvsignore"
alias rsync-update="rsync -avu --progress -h --exclude-from=$HOME/.cvsignore"
alias rsync-synchronize="rsync -avu --delete --progress -h --exclude-from=$HOME/.cvsignore"

# Files permissions
alias 400='chmod 400 -R'
alias 600='chmod 600 -R'
alias 640='chmod 640 -R'
alias 644='chmod 644 -R'
alias 755='chmod 755 -R'
alias 775='chmod 775 -R'
alias 777='chmod 777 -R'
alias www="chown www-data:www-data * .* -R"
alias mx='chmod u+x'

# SSH helpers
alias tunnel='ssh -f -N' ## Create a tunnel
alias tunnel-mysql='ssh -N -L 3307:localhost:3306' ## Create a MySQL tunnel
alias tunnel-socks='ssh -N -D 8080' ## SOCKS proxy
alias tunnel-list='ps aux | grep "ssh -f -N" | grep -v "grep"' ## List tunnels

# Datetime helpers
alias week='date +%V'
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Network & ISP tests
alias myip='dig +short myip.opendns.com @resolver1.opendns.com'
alias myips="ifconfig -a | grep -o 'inet6\? \(ad\?dr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:|adr:)? ?/, \"\"); print }' | grep -v '127.0.0.1' | grep -v '::1'"
alias localip="ifconfig | grep -Eo 'inet (addr:|adr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
alias speedtest="wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip"
alias ipstats="netstat -ntu | tail -n +3 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n"
alias ports="lsof -ni | grep LISTEN"
alias ns="nslookup"
alias he="sudo $EDITOR /etc/hosts"

# Curl & web helpers
alias dl='curl --continue-at - --location --progress-bar --remote-name --remote-time' ## download a file
alias weather='curl -A curl wttr.in'
alias wget-site='wget --mirror -p --convert-links -P'
alias header='curl-header'
alias purge='curl-purge'
for method in GET HEAD POST PUT DELETE PURGE TRACE OPTIONS; do
    alias "$method"="http '$method'"
done

# Online pastebins
alias sprunge="curl -F 'sprunge=<-' http://sprunge.us"
alias clbin="curl -F 'clbin=<-' https://clbin.com"

# Because Oo
alias tableflip="echo '(ノಠ益ಠ)ノ彡┻━┻'" ## see https://gist.github.com/endolith/157796
alias utf8test="wget -qO- http://8n1.org/utf8" ## test terminal UTF8 capabilities
