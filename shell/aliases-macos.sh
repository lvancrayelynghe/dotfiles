# macOS-only aliases, shared by bash AND zsh. Sourced last by shell/aliases.sh,
# because the GNU tool aliases below deliberately override the generic grep
# ones defined there. Keep POSIX-friendly: no zsh-only syntax.

# Use GNU tools instead of the BSD ones (brew coreutils/gawk/gnu-sed/grep).
# Backslash-quote the target so the shell runs the binary instead of
# re-expanding it as an alias: gls is also the `git log --stat` shortcut.
alias ls='\gls --color=auto'
alias awk='\gawk'
alias sed='\gsed'
alias grep='\ggrep --color=auto'
alias vgrep='\ggrep -v --color=auto'
alias egrep='\ggrep -E --color=auto'
alias fgrep='\ggrep -F --color=auto'

alias o='open'
alias pwdc=' pwd | tr -d "\n" | pbcopy' ## copy working directory to clipboard

# System commands
alias halt="osascript -e 'tell app \"System Events\" to shut down'"
alias reboot="osascript -e 'tell app \"System Events\" to restart'"
alias agall='brew update && brew upgrade && brew cleanup -s && brew doctor'
alias brewall='brew update && brew upgrade && brew cleanup -s && brew doctor'

# Show/hide hidden files in Finder
alias show='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hide='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop='defaults write com.apple.finder CreateDesktop -bool false && killall Finder'
alias showdesktop='defaults write com.apple.finder CreateDesktop -bool true && killall Finder'

# Line wrapping
alias wrap='tput smam'
alias nowrap='tput rmam'

# Stuff I never really use but cannot delete either because of http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"

alias afk='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'

# Keep the display awake through Hammerspoon, so that the terminal and the ☕️
# menubar item drive one and the same assertion -- a `caffeinate -d` here would
# hold a second one and the icon would then lie. The hammerspoon:// URL is bound
# in hammerspoon/caffeinate.lua and needs nothing installed, unlike hs.ipc.
# pmset is what actually holds the answer, `open` returning before Hammerspoon
# has even seen the URL.

# on when Hammerspoon holds the display sleep assertion, off otherwise
caffeine_state() {
    pmset -g assertions |
        awk '/\(Hammerspoon\)/ && /PreventUserIdleDisplaySleep/ { found = 1 }
             END { print found ? "on" : "off" }'
}

# Toggle the display-sleep block, or force it: caffeine [on|off|status]
caffeine() {
    local want state i=0
    state=$(caffeine_state)

    case "${1:-toggle}" in
        toggle) [ "$state" = on ] && want=off || want=on ;;
        on|off) want="$1" ;;
        status) echo "$state"; return 0 ;;
        *) echo 'caffeine: usage: caffeine [toggle|on|off|status]' >&2; return 1 ;;
    esac

    open -g "hammerspoon://caffeinate?action=$want" || return 1

    while [ "$state" != "$want" ] && [ "$i" -lt 20 ]; do
        sleep 0.05
        state=$(caffeine_state)
        i=$((i + 1))
    done

    [ "$state" = on ] && echo '☕️ caffeinated' || echo '💤 no caffeine'
}

# Ignore macos files
alias zip='zip -x *.DS_Store -x *__MACOSX* -x *.AppleDouble*'

# Cleanup .DS_Store droppings
alias rmds="find . -type f -name '*.DS_Store' -ls -delete"

# Flush DNS
alias flushdns='sudo killall -HUP mDNSResponder'

# Network. Apple ships no `ip`/`ss`, so ifconfig stays -- but through its own
# helpers (route, ipconfig) rather than regexes over its human-readable output.

# IPv4 of the interface carrying the default route
localip() {
    local iface
    iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
    [ -n "$iface" ] || { echo 'localip: no default route' >&2; return 1; }
    ipconfig getifaddr "$iface"
}

# Every address of every interface, loopback excluded
myips() {
    ifconfig | awk '/^\tinet6? / {print $2}' | grep -v '^::1$\|^127\.'
}

# Connections grouped by remote host. macOS netstat separates the port with a
# dot, and its -u means UNIX sockets, not UDP -- hence `-p tcp` and the sub().
ipstats() {
    netstat -n -p tcp | awk 'NR>2 {sub(/\.[0-9]+$/, "", $5); print $5}' \
        | sort | uniq -c | sort -rn
}

# Listening TCP sockets, asked for precisely rather than grepped out of lsof
alias ports='lsof -nP -iTCP -sTCP:LISTEN'

# Quick-Look preview files from the command line
alias ql='qlmanage -p &>/dev/null'
