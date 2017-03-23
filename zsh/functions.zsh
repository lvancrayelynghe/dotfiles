#!/usr/bin/env zsh

# List content of archive but don't extract
function ll-archive() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2|*.tbz2|*.tbz)  tar -jtf "$1"     ;;
            *.tar.gz)                tar -ztf "$1"     ;;
            *.tar|*.tgz|*.tar.xz)    tar -tf  "$1"     ;;
            *.gz)                    gzip -l  "$1"     ;;
            *.rar)                   rar vb   "$1"     ;;
            *.zip)                   unzip -l "$1"     ;;
            *.7z)                    7z l     "$1"     ;;
            *.lzo)                   lzop -l  "$1"     ;;
            *.xz|*.txz|*.lzma|*.tlz) xz -l    "$1"     ;;
        esac
    else
        echo "Sorry, '$1' is not a valid archive."
        echo "Valid archive types are:"
        echo "tar.bz2, tar.gz, tar.xz, tar, gz,"
        echo "tbz2, tbz, tgz, lzo, rar"
        echo "zip, 7z, xz and lzma"
    fi
}

# Extract an archive
function extract() {
    if [ -z "$2" ]; then 2="."; fi
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2|*.tbz2|*.tbz)       mkdir -v "$2" 2>/dev/null ; tar xvjf "$1" -C "$2"  ;;
            *.tar.gz|*.tgz)               mkdir -v "$2" 2>/dev/null ; tar xvzf "$1" -C "$2"  ;;
            *.tar.xz)                     mkdir -v "$2" 2>/dev/null ; tar xvJf "$1"          ;;
            *.tar)                        mkdir -v "$2" 2>/dev/null ; tar xvf  "$1" -C "$2"  ;;
            *.rar)                        mkdir -v "$2" 2>/dev/null ; unrar x  "$1"          ;;
            *.zip)                        mkdir -v "$2" 2>/dev/null ; unzip    "$1" -d "$2"  ;;
            *.7z)                         mkdir -v "$2" 2>/dev/null ; 7z x     "$1" -o"$2"   ;;
            *.lzo)                        mkdir -v "$2" 2>/dev/null ; lzop -d  "$1" -p "$2"  ;;
            *.gz)                         gunzip "$1"                                        ;;
            *.bz2)                        bunzip2 "$1"                                       ;;
            *.Z)                          uncompress "$1"                                    ;;
            *.xz|*.txz|*.lzma|*.tlz)      xz -d "$1"                                         ;;
            *)
        esac
    else
        echo "Sorry, '$1' could not be decompressed."
        echo "Usage: extract <archive> <destination>"
        echo "Example: extract PKGBUILD.tar.bz2 ."
        echo "Valid archive types are:"
        echo "tar.bz2, tar.gz, tar.xz, tar, bz2,"
        echo "gz, tbz2, tbz, tgz, lzo,"
        echo "rar, zip, 7z, xz and lzma"
    fi
}

# compress a file or folder
function compress() {
        case "$1" in
        tar.bz2|.tar.bz2) tar cvjf "${2%%/}.tar.bz2" "${2%%/}/" ;;
        tbz2|.tbz2)       tar cvjf "${2%%/}.tbz2" "${2%%/}/"    ;;
        tbz|.tbz)         tar cvjf "${2%%/}.tbz" "${2%%/}/"     ;;
        tar.xz)           tar cvJf "${2%%/}.tar.xz" "${2%%/}/"  ;;
        tar.gz|.tar.gz)   tar cvzf "${2%%/}.tar.gz" "${2%%/}/"  ;;
        tgz|.tgz)         tar cvjf "${2%%/}.tgz" "${2%%/}/"     ;;
        tar|.tar)         tar cvf  "${2%%/}.tar" "${2%%/}/"     ;;
        rar|.rar)         rar a "${2}.rar" "$2"                 ;;
        zip|.zip)         zip -r -9 "${2}.zip" "$2"             ;;
        7z|.7z)           7z a "${2}.7z" "$2"                   ;;
        lzo|.lzo)         lzop -v "$2"                          ;;
        gz|.gz)           gzip -r -v "$2"                       ;;
        bz2|.bz2)         bzip2 -v "$2"                         ;;
        xz|.xz)           xz -v "$2"                            ;;
        lzma|.lzma)       lzma -v "$2"                          ;;
        *)                echo "Compress a file or directory."
        echo "Usage:   compress <archive type> <filename>"
        echo "Example: ac tar.bz2 PKGBUILD"
        echo "Please specify archive type and source."
        echo "Valid archive types are:"
        echo "tar.bz2, tar.gz, tar.gz, tar, bz2, gz, tbz2, tbz,"
        echo "tgz, lzo, rar, zip, 7z, xz and lzma." ;;
    esac
}

# Show aliases and functions cheat-sheet
function cheat-sheet() {
    cat "${DOTFILES_PATH}/zsh/aliases.zsh" |
        perl -p0e 's/\nelse\n.*?\nfi\n/\n/sg' |
        perl -p0e 's/\nfor .*?done\n//sg' |
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

    cat "${DOTFILES_PATH}/zsh/functions.zsh" |
        grep "^function" -B1 |
        grep -v "^--" |
        awk '{printf "%s%s",$0,NR%2?"\t":"\n" ; }' |
        awk -F'\t' '{ t = $1; $1 = $2; $2 = t; print; }' |
        sed -r 's/^function ([A-Za-z0-9!=._-]+)(.*) # (.*)/\x1b[36m\1\x1b[0m\t\x1b[33m\3\x1b[0m/g' |
        awk 'BEGIN { FS = "\t" } ; { printf "%-35s %s\n", $1, $2}'
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

# Columns git show
function columns-git-show() {
    cdiff -s -w 0 "$1^" "$1"
}

# Opens the current directory in Sublime Text, otherwise opens the given location
function open-with-sublime-text() {
    if [ $# -eq 0 ]; then
        subl -a .;
    else
        subl -a "$@";
    fi;
}

# Opens the current directory in Atom, otherwise opens the given location
function open-with-atom() {
    if [ $# -eq 0 ]; then
        atom .;
    else
        atom "$@";
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

# Find and replace in current dir
function find-and-replace() {
    if [ ${#} -ne 2 ]; then
        echo 'Find and replace in current dir'
        echo 'Usage: find-and-replace "find_this" "replace_with"'
    else
        find_this="$1"
        replace_with="$2"
        shift 2

        items=$(ag -l --nocolor "$find_this" "$@")
        temp="${TMPDIR:-/tmp}/replace_temp.$$"
        IFS=$'\n'
        for item in $items; do
          sed "s/$find_this/$replace_with/g" "$item" > "$temp" && mv "$temp" "$item"
        done
    fi
}

# Backup a file
function backup-file() {
    cp -r "$1"{,.bak};
    #cp $1 $1_`date +%H:%M:%S_%d-%m-%Y`
}

# Encrypt a file
function encrypt() {
    openssl des3 -in $* -out $*.secret
}

# Decrypt a file
function decrypt() {
    openssl des3 -d -in $* -out $*.plain
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

# Notes tool
function note() {
    case $@ in
        "-s") subl ~/.note.md;;
        "-e") vim  ~/.note.md;;
          "") cat  ~/.note.md | less;;
           *) echo -e "$@\n" >> ~/.note.md
              echo -e "\033[0;37m\"$@\" \033[1;30madded to your notes.\033[0m\n";;
    esac
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

# Rename TV shows files
function rename-tv-shows() {
    if [ "$#" -lt 1 ]; then
        echo "Missing TV show name"
        echo "  Usage : rename-tv-shows Name of the TV show"
    else
        SHOWNAME=$@
        SHOWNAME=${SHOWNAME/\%/\%\%} # Escape "%" for sprintf
        RENAME="s/.*[s,S](\d{1,2}).*[e,E](\d{1,2}).*\.(.*)/sprintf '$SHOWNAME S%02dE%02d.%s', \$1, \$2, \$3/e"
        COUNT=`rename -v -n "$RENAME" * | wc -l`
        if [ "$COUNT" -lt 1 ]; then
            echo "No file found"
        else
            rename -v -n "$RENAME" *
            printf "\033[0;33mRename files ? [y/n] \033[0m"
            if [ -n "$ZSH_VERSION" ]; then
                read action
            else
                read -n 1 action
            fi
            if [ "$action" = "y" ] || [ "$action" = "Y" ]; then
                rename "$RENAME" *
            fi
        fi
        echo ""
    fi
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
