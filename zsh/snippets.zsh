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

# Claude Code snippets
# List Claude Code subagents with model + effort, freshest first. Active-only by default:
# a subagent counts as active when its transcript was touched within the freshness window
# (its .meta.json is written once at spawn, so activity lives in the .jsonl mtime).
#   -a          show every subagent, whatever its age
#   -p PATH|all scope to another project path, or all projects (default: $PWD)
#   $1          freshness window in seconds (default 120)
# Colourised on a tty (NO_COLOR disables, CLICOLOR_FORCE forces): description bold cyan,
# type blue, model green, effort magenta.
function claude:subagents() {
  zmodload -F zsh/stat b:zstat 2>/dev/null
  local root=~/.claude/projects proj="$PWD" all=0 win=120 j m age now shown=0
  while [[ "$1" == -* ]]; do
    case "$1" in
      -a) all=1 ;;
      -p) proj="$2"; shift ;;
      *)  echo "usage: claude:subagents [-a] [-p PATH|all] [window_seconds]" >&2; return 2 ;;
    esac
    shift
  done
  [[ -n "$1" ]] && win="$1"
  local jsonls
  if [[ "$proj" == all ]]; then
    jsonls=($root/*/*/subagents/agent-*.jsonl(N.om))    # N nullglob, . plain, om newest first (like ls -t)
  else
    jsonls=($root/${proj//\//-}/*/subagents/agent-*.jsonl(N.om))
  fi
  (( $#jsonls )) || { echo "No subagents found (project: $proj)" >&2; return 1 }
  # colours: description = bold cyan, type = blue, model = green, effort = magenta.
  # Off when piped or $NO_COLOR is set; force on with $CLICOLOR_FORCE.
  local cD cT cM cE cd c0
  if [[ -n "$CLICOLOR_FORCE" || ( -t 1 && -z "$NO_COLOR" ) ]]; then
    cD=$'\e[1;36m' cT=$'\e[34m' cM=$'\e[32m' cE=$'\e[35m' cd=$'\e[2m' c0=$'\e[0m'
  fi
  now=$(date +%s)
  local id type desc rmodel reff hage meta
  for j in $jsonls; do
    [[ -f "$j" ]] || continue
    age=$(( now - $(zstat +mtime "$j") ))
    (( all || age <= win )) || continue
    shown=1
    id="${${j:t}%.jsonl}"
    m="${j%.jsonl}.meta.json"
    type='?'; desc=''
    if [[ -f "$m" ]]; then
      meta="$(<"$m")"
      [[ "$meta" == *'"agentType":"'*   ]] && type=${${meta##*'"agentType":"'}%%'"'*}
      [[ "$meta" == *'"description":"'* ]] && desc=${${meta##*'"description":"'}%%'"'*}
    fi
    [[ -n "$desc" ]] || desc="$id"
    rmodel=$(grep -om1 '"model":"[^"]*"'  "$j" 2>/dev/null); rmodel=${${rmodel#*:\"}%\"}
    reff=$(grep -om1   '"effort":"[^"]*"' "$j" 2>/dev/null); reff=${${reff#*:\"}%\"}
    if   (( age < 120 ));  then hage="${age}s"
    elif (( age < 7200 )); then hage="$(( age / 60 ))m"
    else                        hage="$(( age / 3600 ))h"
    fi
    print -r -- "${cM}●${c0} ${cD}${desc}${c0}  ${cd}(${hage})${c0}"
    print -r -- "  ${cT}${type}${c0}${cd} · ${c0}${cM}${rmodel:-?}${c0}${cd} · ${c0}${cE}${reff:-–}${c0}${cd}  ·  ${id}${c0}"
  done
  (( shown )) || echo "No active subagents (<=${win}s). Use -a to show all." >&2
}
