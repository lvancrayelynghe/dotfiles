# Linux-only aliases, shared by bash AND zsh. Sourced last by shell/aliases.sh.
# This is what the LEMP servers get. Keep POSIX-friendly: no zsh-only syntax.

alias o='xdg-open 2>/dev/null'
alias pwdc=' pwd | tr -d "\n" | xclip -selection clipboard' ## copy working directory to clipboard

# System commands
alias apt-installed="aptitude search '~i!~M'"
if [ "${EUID:-$(id -u)}" != 0 ]; then
    alias halt='sudo shutdown -h now'
    alias reboot='sudo shutdown -r now'
    alias apt='sudo apt-get'
    alias agi='sudo apt-get install'
    alias agr='sudo apt-get remove'
    alias agu='sudo apt-get update'
    alias agg='sudo apt-get upgrade'
    alias ags='sudo apt-cache search'
else
    alias halt='shutdown -h now'
    alias reboot='shutdown -r now'
    alias apt='apt-get'
    alias agi='apt-get install'
    alias agr='apt-get remove'
    alias agu='apt-get update'
    alias agg='apt-get upgrade'
    alias ags='apt-cache search'
fi

# Network, through iproute2 rather than the deprecated net-tools
alias myips='ip -brief address' ## every interface and its addresses
alias localip="ip -4 -brief address show scope global | awk '{sub(/\/.*/, \"\", \$3); print \$3}'"
alias ports='ss -tulnp' ## listening TCP/UDP sockets
alias ipstats="ss -tun | tail -n +2 | awk '{sub(/:[^:]*\$/, \"\", \$6); print \$6}' | sort | uniq -c | sort -rn" ## connections per remote host

# System stats
alias free='free -h'
alias iotop='iotop -Poa' ## iotop with only processes using i/o + accumulated i/o
alias dmesg='dmesg -T | sed -e "s|\(^.*$(date +%Y)]\)\(.*\)|\x1b[0;34m\1\x1b[0m - \2|g"' ## dmesg with colored human-readable dates

# Datetime helpers
alias cal='cal -3'
