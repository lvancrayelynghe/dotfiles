#!/usr/bin/env zsh

# Find snippets
function find:days()         { find . -type f -mtime -$1 | grep -v "/.git/" }
function find:minutes()      { find . -type f -mmin -$1 | grep -v "/.git/" }
function find:biggest()      { find . -type f -print0 | xargs -0 du | sort -n | tail -10 | cut -f2 | xargs -I{} du -sh {} }
function find:biggest-dirs() { find . -maxdepth 1 -type d -print0 | xargs -0 du --max-depth=1 | sort -rn | head -n 11 | tail -n +2 | cut -f2 | xargs -I{} du -sh {} }

function find:content()      { grep --include=\*.php -rnw '.' -e "$1" }
function find:duplicated()   { fdupes -r . }

# PHP lint all files
function php:lint()          { find -iname '*.php' -exec php -l {} \; }

# Docker snippets
function docker:clean()      { docker rmi -f $(docker images | grep "<none>" | awk "{print \$3}") }
function docker:killall()    { docker kill $(docker ps -q) }

# System snippets
function journal:vacuum()    { journalctl --vacuum-size=200M }

# SSH snippets
# (N) so an empty config.d is not a zsh "no matches found" error
function ssh:list()          { grep -h '^[[:space:]]*Host[[:space:]]' ~/.ssh/config ~/.ssh/config.d/*.conf(N) 2>/dev/null | awk '{for (i = 2; i <= NF; i++) if ($i != "*") print $i}' | sort -u }
function ssh:keygen()        { ssh-keygen -t rsa -b 4096 -C "$1"}
function ssh:mount()         { mkdir -p "$2" 2> /dev/null ; sshfs "$1" "$2" } # $1: [user@]host:[dir] / $2: mountpoint
function ssh:mounts()        { \ps x | grep sshfs | grep -v " grep " | awk '{$1=$2=$3=$4="";print $0}' | xargs }

# Samba shares
function smb:mount()         { mkdir -p "$2" 2> /dev/null ; sudo mount.cifs $@ } # $1: //host/sharename / $2: mountpoint
function smb:unmount()       { sudo umount "$1" ; rmdir "$1" 2> /dev/null  } # $1: mountpoint

# Trash
function trash:size()        { du -hs ~/.local/share/Trash | cut -f1 }
function trash:list()        { ls -al ~/.local/share/Trash/**/*(.) }
function trash:clear()       { rm -rf ~/.local/share/Trash/* }

# Terminal snippets
function term:test256()      { for code in $(seq -w 0 255); do for attr in 0 1; do printf "%s-%03s %bTest%b\n" "${attr}" "${code}" "\e[${attr};38;05;${code}m" "\e[m"; done; done | column -c $((COLUMNS*2)) }
