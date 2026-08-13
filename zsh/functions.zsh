#!/usr/bin/env zsh

# Show aliases and functions cheat-sheet
function cheat-sheet() {
    local -a files
    files=(
        "${DOTFILES_PATH}/shell/aliases.sh"
        "${DOTFILES_PATH}/shell/aliases-git.sh"
        "${DOTFILES_PATH}/shell/aliases-docker.sh"
        "${DOTFILES_PATH}/shell/aliases-dev.sh"
        "${DOTFILES_PATH}/shell/aliases-net.sh"
    )
    # only this machine's OS file, so the other platform's aliases stay out
    if [[ "$OSTYPE" == darwin* ]]; then
        files+=("${DOTFILES_PATH}/shell/aliases-macos.sh")
    else
        files+=("${DOTFILES_PATH}/shell/aliases-linux.sh")
    fi
    files+=("${DOTFILES_PATH}/zsh/aliases.zsh")

    # Drop each file's leading header block: it explains the file, and would
    # otherwise render as a run of empty section titles.
    awk 'FNR==1 {h=1; skip=0}
         /^# >>> plumbing/ {skip=1}
         skip {next}
         h && /^#/ {next} h && /^$/ {h=0; next} {h=0; print}' "${files[@]}" |
        perl -p0e 's/\n# [^\n]*\n[A-Za-z_][A-Za-z0-9_-]*\(\) \{.*?\n\}\n/\n/sg' |
        perl -p0e 's/\nelse\n.*?\nfi\n/\n/sg' |
        perl -p0e 's/\nfor .*?done\n//sg' |
        grep -v '_ALIASES_DIR' |
        grep -v "^if " |
        grep -v "^elif " |
        grep -v "^fi$" |
        grep -v "^    if " |
        grep -v "^    elif " |
        grep -v "^    else" |
        grep -v "^    fi$" |
        sed -r 's/^[[:space:]]+(.*)/\1/g' |
        sed -r 's/^# (.*)/\x1b[32m\x1b[1m\n# \1\x1b[0m/' |
        sed -r 's/## (.*)/\x1b[33m## \1\x1b[0m/' |
        sed -r 's/-- -/-/' |
        sed -r 's/alias -g/alias/' |
        sed -r 's/^alias (-g )?([A-Za-z0-9!=._-]+)=(.*)/\x1b[36m\2\x1b[0m\t\3/g' |
        awk 'BEGIN { FS = "\t" } ; { printf "%-30s %s\n", $1, $2}' |
        sed -r "s/'(.*)'/\1/" |
        sed -r 's/"(.*)"/\1/'
    echo ""
    echo "\x1b[32m\x1b[1m\n# Functions\x1b[0m"

    # Pair each definition with the comment line right above it. Handles both
    # `function name()` and POSIX `name()`, so the helpers that live in the
    # shared shell/aliases-*.sh files are listed too.
    awk '
        /^# / { desc = substr($0, 3); next }
        /^(function )?[A-Za-z0-9!=._-]+ ?\(\)/ {
            name = $0
            sub(/^function /, "", name)
            sub(/ ?\(\).*/, "", name)
            if (desc != "") printf "\033[36m%-33s\033[0m \033[33m%s\033[0m\n", name, desc
            desc = ""
            next
        }
        { desc = "" }
    ' "${DOTFILES_PATH}/zsh/functions.zsh" "${files[@]}"
    echo ""
}

# Find all git repositories in a path and run git pull
function git-repositories-pull() {
    if [ $# -eq 0 ]; then
        find . -type d -name ".git" -print0 | xargs -0 -n1 dirname | grep -v -e "\(/.cache/\|/.config/\)" | xargs -I repodir sh -c 'cd repodir ; printf "repodir ... " ; git pull'
    else
        find "$@" -type d -name ".git" -print0 | xargs -0 -n1 dirname | grep -v -e "\(/.cache/\|/.config/\)" | xargs -I repodir sh -c 'cd repodir ; printf "repodir ... " ; git pull'
    fi;
}

# Opens the current directory in Sublime Text, otherwise opens the given location
function open-with-sublime-text() {
    if [ $# -eq 0 ]; then
        subl -a .;
    else
        subl -a "$@";
    fi;
}

# Opens the current directory in Vim, otherwise opens the given location
function open-with-vim() {
    if [ $# -eq 0 ]; then
        vim .;
    else
        vim "$@";
    fi;
}

# Passthru grep
function grep-passthru() {
    if [ -z "$2" ]; then
        egrep "$1|$"
    else
        egrep "$1|$" $2
    fi
}

# Highlight a match in given color
function highlight() {
    declare -A fg_color_map
    fg_color_map[black]=30
    fg_color_map[red]=31
    fg_color_map[green]=32
    fg_color_map[yellow]=33
    fg_color_map[blue]=34
    fg_color_map[magenta]=35
    fg_color_map[cyan]=36

    fg_c=$(echo -e "\e[1;${fg_color_map[$1]}m")
    c_rs=$'\e[0m'
    sed -u s"/$2/$fg_c\0$c_rs/g"
}

# Commands usage statistics
function history-stats() {
    fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n25
}

# Human readable path variable
function path() {
    LF=$(printf '\\\012_')
    LF=${LF%_}

    echo $PATH | sed 's/:/'"$LF"'/g'
}

# Recursively fix dir/file permissions on a given directory
function fix-dir-perm() {
    if [ -d $1 ]; then
        find $1 -type d -exec chmod 755 {} \;
        find $1 -type f -exec chmod 644 {} \;
    else
        echo "$1 is not a directory."
    fi
}

# Get an HTTP response header only
function curl-header() {
    curl -s -D - "${1}" -o /dev/null
}

# Send a purge query (Varnish)
function curl-purge() {
    curl -s -X PURGE "${1}" | grep "title" | sed "s_<\([^<>][^<>]*\)>\([^<>]*\)</\1>_$prefix\2_g" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# Create a directory and "cd" into it
function mkdir-cd() {
    mkdir "${1}" && cd "${1}"
}

# Find and replace in current dir. Patterns are Rust regexes (sd), not sed BRE:
# capture groups are (…) and the replacement uses $1, not \1.
function find-and-replace() {
    if [ ${#} -lt 2 ]; then
        echo 'Find and replace in current dir'
        echo 'Usage: find-and-replace "find_this" "replace_with" [path...]'
        return 2
    fi

    local find_this="$1" replace_with="$2"
    shift 2

    local files
    files=$(rg -l --no-heading --color=never -e "$find_this" "$@") || {
        echo "find-and-replace: nothing matches '$find_this'" >&2
        return 1
    }

    # sd edits in place, so no temp file dance
    printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 sd -- "$find_this" "$replace_with"
}

# Backup a file
function backup-file() {
    cp -r "$1"{,.bak};
    #cp $1 $1_`date +%H:%M:%S_%d-%m-%Y`
}

# Encrypt a file
function encrypt() {
    openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -salt -in "$1" -out "$1.secret"
}

# Decrypt a file
function decrypt() {
    openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -d -in "$1" -out "${1%.secret}.plain"
}

# Small calc function
function calc() {
    echo "scale=2;$@" | bc -l
}

# Shortcut calc function
function = () {
    # credit goes to arzzen/calc.plugin.zsh
    echo "scale=2;$@" | bc -l
}

# Make a port (default 80) "real life" speeds
function slowport {
    if [ -z "$1" ]; then
        port=80
    else
        port=$1
    fi

    sudo ipfw pipe 1 config bw 100KByte/s
    sudo ipfw add 1 pipe 1 src-port $port
    sudo ipfw add 1 pipe 1 dst-port $port
    echo "Port $port succesfully slowed."
}

# Restore ports speed
function unslowport {
    sudo ipfw delete 1
    echo "Port succesfully un-slowed."
}

# Create a data URI from file
function datauri() {
    local mimeType=$(file -b --mime-type "$1");
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8";
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')";
}

# Smart JPG / PNG images resize
function smartresize() {
    if [ "$1" == "" ]
        then echo "Syntax : smartresize inputfile width outputdir"
    elif [ "$2" == "" ]
        then echo "Syntax : smartresize inputfile width outputdir"
    elif [ "$3" == "" ]
        then echo "Syntax : smartresize inputfile width outputdir"
    else
        mogrify -path "$3" -filter Triangle -define filter:support=2 -thumbnail "$2" -unsharp 0.25x0.08+8.3+0.045 -dither None -posterize 136 -quality 82 -define jpeg:fancy-upsampling=off -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all -interlace none -colorspace sRGB "$1"
    fi
}

# Generate a password using pwgen
function strong-password() {
    echo "Syntax : strong-password [-B] [-y] [-s] [length]"
    echo "        -B : Don't use characters that could be confused"
    echo "        -y : Include at least one special character in the password"
    echo "        -s : Generate  completely  random, hard-to-memorize passwords"
    echo "    length : Password length"
    echo ""
    pwgen "$@"
}

# Download all files of a certain type with wget #
# usage: wgetall mp3 http://example.com/download/
function wgetall() {
    wget -r -l2 -nd -Nc -A.$@ $@ ;
}

# Animated gifs from any video (from alex sexton gist.github.com/SlexAxton/4989674)
function gifify() {
    if [[ -n "$1" ]]; then
        if [[ $2 == '--good' ]]; then
            ffmpeg -i $1 -r 10 -vcodec png out-static-%05d.png
            time convert -verbose +dither -layers Optimize -resize 900x900\> out-static*.png  GIF:- | gifsicle --colors 128 --delay=5 --loop --optimize=3 --multifile - > $1.gif
            rm out-static*.png
        else
            ffmpeg -i $1 -s 600x400 -pix_fmt rgb24 -r 25 -f gif - | gifsicle --optimize=3 --delay=3 > $1.gif
        fi
    else
        echo "proper usage: gifify <input_movie.mov>. You DO need to include extension."
    fi
}

# Matrix
function matrix() {
    echo -e "\e[1;40m" ; clear ; characters=$( jot -c 94 33 | tr -d '\n' ) ; while :; do echo $LINES $COLUMNS $(( $RANDOM % $COLUMNS)) $(( $RANDOM % 72 )) $characters ;sleep 0.05; done|gawk '{ letters=$5; c=$4; letter=substr(letters,c,1);a[$3]=0;for (x in a) {o=a[x];a[x]=a[x]+1; printf "\033[%s;%sH\033[2;32m%s",o,x,letter; printf "\033[%s;%sH\033[1;37m%s\033[0;0H",a[x],x,letter;if (a[x] >= $1) { a[x]=0; } }}'
}

# Let's be corporate
function robco() {
echo "$(tput setaf 2)

  ██████████▒             ████▒       ███████████
  ███▒▒▒▒███▒▒            ████▒▒      ███████████▒▒
  ███▒▒▒▒███▒▒            ████▒▒      ███▒▒▒▒▒███▒▒
  ███▒▒▒▒███▒▒            ████▒▒      ███▒▒▒▒▒███▒▒
  ███▒▒  ███▒▒            ████▒▒      ███▒▒   ███▒▒
  ███▒▒  ███▒▒            ████▒▒      ███▒▒   ███▒▒
  ███▒▒  ███▒▒ ████████   █████████   ███▒▒   ▒▒▒▒▒ ████████
  ███▒██████▒▒ █████████▒ ██████████▒ ███▒▒        █████████▒▒
  ███▒██████▒▒ ███▒▒▒███▒▒████▒▒▒███▒▒███▒▒        ████▒▒▒██▒▒
  ███▒███▒▒▒▒▒ ███▒▒▒███▒▒████▒▒▒███▒▒███▒▒        ████▒▒▒██▒▒
  ███▒████▒▒▒  ███▒▒ ███▒▒████▒▒ ███▒▒███▒▒        ████▒▒ ██▒▒
  ███▒▒███▒▒   ███▒▒ ███▒▒████▒▒ ███▒▒███▒▒   ███  ████▒▒ ██▒▒
  ███▒▒███▒▒   ███▒▒ ███▒▒████▒▒ ███▒▒███▒▒   ███▒▒████▒▒ ██▒▒
  ███▒▒ ███▒   ███▒▒ ███▒▒████▒▒ ███▒▒███▒▒   ███▒▒████▒▒ ██▒▒
  ███▒▒ ███▒▒  ███▒▒ ███▒▒████▒  ███▒▒███████████▒▒████▒  ██▒▒
  ███▒▒  ███▒▒ █████████▒▒██████████▒▒███████████▒▒█████████▒▒
  ▒▒▒▒▒  ▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒
   ▒▒      ▒▒   ▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒

$(tput sgr0)"
}

# Because Metroid !
function metroid() {
cat << EOF

                  [48;5;77m                [49m
              [48;5;77m    [48;5;16m                [48;5;77m    [49m
            [48;5;77m  [48;5;16m                        [48;5;77m  [49m
          [48;5;77m  [48;5;16m      [48;5;202m  [48;5;16m                    [48;5;77m  [49m
        [48;5;77m  [48;5;16m    [48;5;223m  [48;5;16m    [48;5;202m        [48;5;16m              [48;5;77m  [49m
        [48;5;77m  [48;5;16m  [48;5;223m    [48;5;16m            [48;5;202m  [48;5;16m          [48;5;202m  [48;5;16m  [48;5;77m  [49m
      [48;5;77m  [48;5;16m  [48;5;223m    [48;5;16m              [48;5;202m  [48;5;16m        [48;5;202m  [48;5;16m    [48;5;77m  [49m
      [48;5;77m  [48;5;16m  [48;5;223m  [48;5;16m            [48;5;202m    [48;5;16m          [48;5;202m  [48;5;16m      [48;5;77m  [49m
    [48;5;77m  [48;5;16m                [48;5;202m  [48;5;223m    [48;5;202m  [48;5;16m        [48;5;202m  [48;5;16m      [48;5;77m  [49m
    [48;5;77m  [48;5;16m                [48;5;223m        [48;5;16m      [48;5;202m  [48;5;16m        [48;5;77m  [49m
    [48;5;77m  [48;5;16m                [48;5;202m  [48;5;223m    [48;5;202m  [48;5;16m      [48;5;202m  [48;5;16m    [48;5;202m    [48;5;16m  [48;5;77m  [49m
  [48;5;77m  [48;5;16m      [48;5;202m    [48;5;16m  [48;5;202m  [48;5;223m  [48;5;202m  [48;5;16m  [48;5;202m    [48;5;16m  [48;5;202m  [48;5;223m  [48;5;202m  [48;5;16m    [48;5;202m  [48;5;16m      [48;5;77m  [49m
  [48;5;77m  [48;5;16m  [48;5;202m    [48;5;16m    [48;5;202m  [48;5;223m      [48;5;202m  [48;5;16m    [48;5;202m  [48;5;223m      [48;5;202m  [48;5;16m          [48;5;77m  [49m
  [48;5;77m  [48;5;16m          [48;5;202m  [48;5;223m        [48;5;16m    [48;5;223m        [48;5;202m  [48;5;16m          [48;5;77m  [49m
  [48;5;77m        [48;5;16m      [48;5;202m  [48;5;223m    [48;5;202m  [48;5;16m    [48;5;202m  [48;5;223m    [48;5;202m  [48;5;16m      [48;5;77m        [49m
  [48;5;77m  [48;5;16m      [48;5;77m    [48;5;16m    [48;5;202m    [48;5;16m        [48;5;202m    [48;5;16m    [48;5;77m    [48;5;16m      [48;5;77m  [49m
  [48;5;77m  [48;5;16m  [48;5;202m    [48;5;16m  [48;5;77m      [48;5;16m                [48;5;77m      [48;5;16m  [48;5;202m    [48;5;16m  [48;5;77m  [49m
    [48;5;77m  [48;5;202m      [48;5;16m    [48;5;77m      [48;5;16m        [48;5;77m      [48;5;16m    [48;5;202m      [48;5;77m  [49m
      [48;5;223m  [48;5;202m    [48;5;16m        [48;5;77m            [48;5;16m        [48;5;202m    [48;5;223m  [49m
      [48;5;223m  [48;5;202m  [49m      [48;5;223m  [48;5;16m    [48;5;77m        [48;5;16m    [48;5;223m  [49m      [48;5;202m  [48;5;223m  [49m
        [48;5;223m  [49m      [48;5;223m    [49m    [48;5;77m    [49m    [48;5;223m    [49m      [48;5;223m  [49m
          [48;5;223m  [39;49m    [48;5;223m  [39;49m                [48;5;223m  [39;49m    [48;5;223m  [49m
                  [48;5;223m  [39;49m            [48;5;223m  [39;49m

EOF
}
