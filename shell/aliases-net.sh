# Network, transfer and SSH aliases, shared by bash AND zsh. Sourced by
# shell/aliases.sh. Keep POSIX-friendly: no zsh-only syntax.
#
# pubkey() is defined here; shell/aliases.sh unaliases the name first, so this
# file must stay downstream of that guard.

# rsync
alias rsync-copy='rsync -av --progress -h --exclude-from=$HOME/.cvsignore'
alias rsync-move='rsync -av --progress -h --remove-source-files --exclude-from=$HOME/.cvsignore'
alias rsync-update='rsync -avu --progress -h --exclude-from=$HOME/.cvsignore'
alias rsync-synchronize='rsync -avu --delete --progress -h --exclude-from=$HOME/.cvsignore'

# Network & ISP tests. localip, myips, ipstats and ports need per-OS commands
# and live in aliases-macos.sh / aliases-linux.sh.
alias myip='dig +short myip.opendns.com @resolver1.opendns.com'
alias ns='dig +short' ## resolve a name, one answer per line
alias nsx='dig' ## full answer, when +short is not enough
alias he='sudo $EDITOR /etc/hosts'

# Curl & web helpers
alias dl='curl --continue-at - --location --progress-bar --remote-name --remote-time' ## download a file
alias weather='curl -A curl wttr.in'
alias wget-site='wget --mirror -p --convert-links -P'
alias header='curl-header'
alias purge='curl-purge'
for method in GET HEAD POST PUT DELETE PURGE TRACE OPTIONS; do
    alias "$method"="xh '$method'"
done
unset method

# Online pastebins
alias clbin="curl -F 'clbin=<-' https://clbin.com"

# SSH helpers
alias tunnel='ssh -f -N' ## Create a tunnel
alias tunnel-mysql='ssh -f -N -L 3307:localhost:3306' ## Create a MySQL tunnel
alias tunnel-socks='ssh -f -N -D 8080' ## SOCKS proxy
alias tunnel-list='ps aux | grep "ssh -f -N" | grep -v "grep"' ## List tunnels

# The agent comes first on purpose: a key held in 1Password (or in the macOS
# keychain) never puts a .pub file in ~/.ssh, so reading the files alone finds
# nothing. Falls back to the files for a server whose keys sit on disk with no
# agent running, and prints instead of copying where there is no clipboard --
# which is the usual case over ssh.
# Copy the SSH public key(s) to the clipboard
pubkey() {
    local keys count
    keys=$(ssh-add -L 2>/dev/null) || keys=''

    if [ -z "$keys" ]; then
        # find, not a glob: an unmatched "$HOME"/.ssh/*.pub aborts the function
        # under zsh instead of quietly expanding to nothing.
        keys=$(find "$HOME/.ssh" -maxdepth 1 -type f -name '*.pub' -exec cat {} + 2>/dev/null)
    fi

    if [ -z "$keys" ]; then
        echo 'pubkey: nothing in the SSH agent, and no *.pub in ~/.ssh' >&2
        echo 'pubkey: if the keys live in 1Password, enable its SSH agent' >&2
        return 1
    fi

    count=$(printf '%s\n' "$keys" | grep -c .)
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s\n' "$keys" | pbcopy
        echo "=> $count key(s) copied to the clipboard"
    elif command -v wl-copy >/dev/null 2>&1; then
        printf '%s\n' "$keys" | wl-copy
        echo "=> $count key(s) copied to the clipboard"
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s\n' "$keys" | xclip -selection clipboard
        echo "=> $count key(s) copied to the clipboard"
    else
        printf '%s\n' "$keys"
    fi

    printf '%s\n' "$keys" | awk '{print "   " $1, ($3 ? $3 : "(no comment)")}'
}
