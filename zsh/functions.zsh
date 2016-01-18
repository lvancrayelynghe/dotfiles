# Extract an archive
function extract() {
	if [ -z "$1" ]; then
	    echo "too few argument" 1>&2
	fi

	if [ -f "$1" ]; then
	    echo "$1: invalid file" 1>&2
	fi

	case "$1" in
	    *.tar.bz2) tar xvjf   "$1" ;;
	    *.tar.gz)  tar xvzf   "$1" ;;
	    *.tar.xz)  tar xv     "$1" ;;
	    *.bz2)     bunzip2    "$1" ;;
	    *.rar)     unrar x    "$1" ;;
	    *.gz)      gunzip     "$1" ;;
	    *.tar)     tar xvf    "$1" ;;
	    *.tbz2)    tar xvjf   "$1" ;;
	    *.tgz)     tar xvzf   "$1" ;;
	    *.zip)     unzip      "$1" ;;
	    *.Z)       uncompress "$1" ;;
	    *.7z)      7z x       "$1" ;;
	    *)
	        echo "$1: oops, cannot be extracted" 1>&2
	        ;;
	esac
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

# Get an HTTP response header only
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
		echo 'Usage: find-and-replace "pattern1" "pattern2"'
	else
		\ack -l "$1" | xargs sed -i "s/$1/$2/g"
	fi
}

# Find files using ZSH globbing
function glob-find-files-by-name() {
	ll **/*(#i)($1)*(.)
}

# Backup a file
function backup-file() {
	cp -r "$1"{,.bak};
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
	echo "scale=2;$@" | bc;
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

# Animated gifs from any video (from alex sexton gist.github.com/SlexAxton/4989674)
function gifify() {
	if [[ -n "$1" ]]; then
		if [[ $2 == '--good' ]]; then
			ffmpeg -i $1 -r 10 -vcodec png out-static-%05d.png
			time convert -verbose +dither -layers Optimize -resize 900x900\> out-static*.png  GIF:- | gifsicle --colors 128 --delay=5 --loop --optimize=3 --multifile - > $1.gif
			rm out-static*.png
		else
			ffmpeg -i $1 -s 600x400 -pix_fmt rgb24 -r 10 -f gif - | gifsicle --optimize=3 --delay=3 > $1.gif
		fi
	else
		echo "proper usage: gifify <input_movie.mov>. You DO need to include extension."
	fi
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
