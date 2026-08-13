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
    alias "$method"="http '$method'"
done
unset method

# Online pastebins
alias clbin="curl -F 'clbin=<-' https://clbin.com"

# SSH helpers
alias tunnel='ssh -f -N' ## Create a tunnel
alias tunnel-mysql='ssh -f -N -L 3307:localhost:3306' ## Create a MySQL tunnel
alias tunnel-socks='ssh -f -N -D 8080' ## SOCKS proxy
alias tunnel-list='ps aux | grep "ssh -f -N" | grep -v "grep"' ## List tunnels

# Copy the SSH public key to the clipboard
pubkey() {
    local key
    for key in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
        if [ -f "$key" ]; then
            if [[ "$OSTYPE" == darwin* ]]; then pbcopy < "$key"; else xclip -selection clipboard < "$key"; fi
            echo "=> $key copied to clipboard"
            return 0
        fi
    done
    echo 'No SSH public key found in ~/.ssh' >&2
    return 1
}
