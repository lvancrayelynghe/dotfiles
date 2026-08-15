#!/usr/bin/env zsh

ZSH_COMPDUMP="$HOME/.cache/zsh-completion-dump"

# Completion directory
if [[ -d ~/.cache/zsh-completions ]]; then
    fpath=(~/.cache/zsh-completions $fpath)
fi

# Load and run compinit and colors (autocompletion)
autoload -U compinit colors
# Trust the existing dump (-C) unless it is older than 24h — the full fpath
# verification costs ~12 ms. Requires extended_glob (global.zsh).
if [[ -n ${ZSH_COMPDUMP}(#qN.mh-24) ]]; then
    compinit -i -C -d "${ZSH_COMPDUMP}"
else
    compinit -i -d "${ZSH_COMPDUMP}"
    # compinit rewrites the dump only when it regenerates it, which it does only
    # when the fpath file count or the zsh version changed. The touch is what
    # re-arms the 24h window in every other case.
    touch "${ZSH_COMPDUMP}"
fi
colors

unsetopt flowcontrol     # output flow control via start/stop characters (usually assigned to ^S/^Q) is disabled in the shell’s editor
setopt menu_complete     # autoselect the first completion entry
setopt auto_menu         # show completion menu on succesive tab press
setopt complete_in_word  # allow completion in word
setopt always_to_end     # if a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word

WORDCHARS='*?_[]~=&;!#$%^(){}<>'

zmodload -i zsh/complist

# Use caching to make completion for commands such as dpkg and apt usable.
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$HOME/.cache/zsh-completion-cache"

# Case-sensitive (all), partial-word, and then substring completion.
# zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# setopt CASE_GLOB

# Case-insensitive (all), partial-word, and then substring completion.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'r:|=*'
unsetopt CASE_GLOB

# Group matches and describe.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only

# Increase the number of errors based on the length of the typed word. A static
# max-errors on the same context would be replaced by this one.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Load directories colors in "ls" command. GNU coreutils is prefixed on macOS,
# where ls is aliased to gls — hence the two names.
# One fork, +0.5 ms, deliberately not cached like fzf and mise: the output
# depends on $TERM, so a cache would serve the wrong palette under tmux or ssh.
_dircolors=${commands[gdircolors]:-$commands[dircolors]}
if [[ -n $_dircolors ]]; then
    [[ -e ~/.dircolors ]] && eval "$("$_dircolors" ~/.dircolors)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
else
    export CLICOLOR=1
    zstyle ':completion:*:default' list-colors ''
fi
unset _dircolors

# https://misc.flogisoft.com/bash/tip_colors_and_formatting
zstyle ':completion:*'                 list-colors 'di=94' 'ln=35' 'so=32' 'ex=92' 'bd=46;34' 'cd=43;34'
zstyle ':completion:*:commands'        list-colors '=*=32'
zstyle ':completion:*:builtins'        list-colors '=*=34'
zstyle ':completion:*:functions'       list-colors '=*=31'
zstyle ':completion:*:aliases'         list-colors '=*=32'
zstyle ':completion:*:parameters'      list-colors '=*=33'
zstyle ':completion:*:reserved-words'  list-colors '=*=31'
zstyle ':completion:*:manuals*'        list-colors '=*=36'
zstyle ':completion:*:options'         list-colors '=^(-- *)=1;34'

zstyle ':completion:*:*:kill:*'                    list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'
zstyle ':completion:*:*:killall:*:processes-names' list-colors '=(#b) #([0-9]#)*=0=01;31'

zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' squeeze-slashes true

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Environmental Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Populate hostname completion. The versioned ssh skeleton declares no Host
# (see CLAUDE.md); they all live in ~/.ssh/config.d/, which has to be read too.
# Read at completion time — no hostname ever lands in this repo.
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${${${=${${(f)"$(cat /etc/hosts 2>/dev/null)"}%%\#*}}:#*.dev}:#*.test}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config ~/.ssh/config.d/*.conf(N) 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete parameters...
zstyle ':completion:*:*:*:parameters' ignored-patterns '*'

# Don't complete uninteresting commands...
zstyle ':completion:*:complete:-command-::commands' ignored-patterns gpu-manager ngettext serialver servertool

# Don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
  dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
  mailman mailnull mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Files types completions. No (#i) needed: file-patterns drives filename
# generation, which the case_glob unset above already makes case-insensitive —
# *.php matches SCRIPT.PHP. Restoring that option makes these case-sensitive.
zstyle ':completion:*:*:php:*'    file-patterns '*.php:php(-.) *(-/):directories' '*:all-files'
zstyle ':completion:*:*:perl:*'   file-patterns '*.pl:perl(-.) *(-/):directories' '*:all-files'
zstyle ':completion:*:*:python:*' file-patterns '*.py:python(-.) *(-/):directories' '*:all-files'
zstyle ':completion:*:*:ruby:*'   file-patterns '*.rb:ruby(-.) *(-/):directories' '*:all-files'
zstyle ':completion:*:*:mpv:*'    file-patterns '*.(avi|mkv|mp4|flac|m4a):medias(-.) *(-/):directories' '*:all-files'
zstyle ':completion:*:*:pinta:*'  file-patterns '*.(jpg|png|gif):images(-.) *(-/):directories' '*:all-files'
zstyle ':completion:*:*:wine:*'   file-patterns '*.exe:exe(-.) *(-/):directories' '*:all-files'

# Ignored patterns. The commands must be the names an alias resolves to: zsh
# builds the completion context from the expansion, so `s` never matches here,
# `open-with-sublime-text` does. The (#i) is required, unlike in file-patterns
# above: this is plain pattern matching, out of reach of case_glob.
zstyle ':completion:*:*:(subl|vim|nvim|vi|emacs|nano|open-with-vim|open-with-sublime-text):*:*files' ignored-patterns '*.(#i)(wav|mp3|flac|ogg|mp4|avi|mkv|webm|iso|dmg|so|o|a|bin|exe|dll|pcap|7z|zip|tar|gz|bz2|rar|deb|pkg|gzip|pdf|mobi|epub|png|jpeg|jpg|gif)'

# SSH/SCP/RSYNC
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
zstyle ':completion:*:(ssh|scp|rsync):*:users' ignored-patterns '*' # Don't complete users on SSH/SCP/RSYNC
