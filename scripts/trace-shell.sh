#!/usr/bin/env bash
#
# Attributes zsh startup cost, per sourced file (default) or per line (-x).
# Answers "where does the time go?" -- for "is the shell fast enough for a
# human?", use scripts/bench-shell.sh.
#
# Works from a throwaway ZDOTDIR shim, so nothing is added to the versioned
# startup files and the measured config is the real one. The shim intercepts
# .zshenv only, then unsets ZDOTDIR to hand control back to ~/.zprofile and
# ~/.zshrc.
#
# The window it covers ends when ~/.zshrc returns. Everything after that --
# prompt rendering, zle-line-init, precmd hooks -- is invisible here by
# construction; that is what bench-shell.sh measures.
#
# Read the numbers as a ranking, not as absolute costs: tracing carries ~20%
# overhead in the default mode (~100 ms of real startup traces as ~120 ms) and
# considerably more with -x. See the DEBUG-trap note below for the bias.
set -euo pipefail

MODE=source
TOP="${TOP:-25}"

usage() {
    cat <<'EOF'
usage: scripts/trace-shell.sh [-x] [-n TOP]

  (default)  per sourced file, via setopt source_trace
  -x         per line, via setopt xtrace -- inflates the timings 40-70%,
             so treat it as a ranking, never as an absolute cost
  -n TOP     how many rows to print (default 25)
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -x|--xtrace) MODE=xtrace; shift ;;
        -n|--top)    TOP="${2:?-n needs a value}"; shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *)           usage >&2; exit 2 ;;
    esac
done

# awk would read a non-numeric TOP as 0 and silently print every row
case "$TOP" in
    ''|*[!0-9]*) echo "trace-shell: -n needs a non-negative integer, got '$TOP'" >&2; exit 2 ;;
esac

command -v zsh >/dev/null 2>&1 || { echo "trace-shell: zsh is required" >&2; exit 1; }

shim="$(mktemp -d "${TMPDIR:-/tmp}/trace-shell.XXXXXX")"
trap 'rm -rf "$shim"' EXIT
: > "$shim/END"

# The single quotes are the point: this block writes zsh source to a file, the
# expansions must survive into the shim rather than happen here.
# shellcheck disable=SC2016
{
    printf '%s\n' "_XT_PS4='+%D{%s.%9.} %N:%i> '"
    # PS4 is prompt-expanded but not parameter-expanded without prompt_subst,
    # hence %D rather than $EPOCHREALTIME: setting a global option here would
    # change what is being measured.
    printf '%s\n' 'PS4=$_XT_PS4'
    # pure assigns PROMPT4 (an alias of PS4 in zsh) in prompt_pure_setup, which
    # strips the timestamp from every trace line emitted afterwards -- and those
    # are the expensive half: without this repair only 17 of the 40 events keep
    # a timestamp.
    #
    # The trap cannot disarm itself once the repair is done. promptinit's
    # set_prompt() opens with `emulate -L zsh`, which sets LOCAL_TRAPS, so the
    # DEBUG trap it saved on entry is restored the moment it returns -- an
    # `unfunction` or `trap - DEBUG` from inside the handler is undone a few
    # commands later. It therefore fires for the whole startup, which is the
    # ~20% overhead: ~100 ms of real startup traces as ~120 ms.
    #
    # That cost is one dispatch per command executed, not per millisecond
    # elapsed, so it over-charges files that run many cheap commands. Measured
    # spread across files: roughly 1.1x to 2x. Read the table as a ranking with
    # that bias in mind, never as absolute cost.
    printf '%s\n' 'TRAPDEBUG() { PS4=$_XT_PS4 }'
    if [ "$MODE" = xtrace ]; then
        printf '%s\n' 'setopt xtrace'
    else
        printf '%s\n' 'setopt source_trace'
    fi
    printf '%s\n' 'unset ZDOTDIR'
    printf '%s\n' '[[ -f ~/.zshenv ]] && source ~/.zshenv'
} > "$shim/.zshenv"

log="$shim/trace.log"
# Sourcing END emits one last trace event, which bounds the final section. The
# path goes through the environment rather than into the command string: a
# TMPDIR containing a space would otherwise split and lose the bound silently.
# shellcheck disable=SC2016
ZDOTDIR="$shim" TRACE_END="$shim/END" \
    zsh -ilc 'source "$TRACE_END"' 2> "$log" >/dev/null || true
if [ "$MODE" = source ] && ! grep -q '/END:[0-9]*> <sourcetrace>' "$log"; then
    echo "trace-shell: the END sentinel never fired; the last section is unbounded" >&2
fi

stamped="$(grep -c '^+[0-9]' "$log" || true)"
# the PS4-repair trap traces itself under -x; it is instrumentation, not config
noise="$(grep -c '^+[0-9][^ ]* TRAPDEBUG:' "$log" || true)"
events=$((stamped - noise))
traced="$(grep -c 'sourcetrace' "$log" || true)"
echo "zsh startup, $MODE attribution — $events timestamped events"
if [ "$MODE" = source ] && [ "$traced" -gt "$events" ]; then
    echo "  warning: $((traced - events)) source event(s) lost their timestamp;" >&2
    echo "  something other than pure is reassigning PS4/PROMPT4 during startup" >&2
fi
echo ""

awk -v mode="$MODE" -v top="$TOP" '
    # +<epoch> <name>:<lineno>> <command>
    /^\+[0-9]+\.[0-9]+ / {
        ts = substr($1, 2) + 0
        rest = substr($0, index($0, " ") + 1)
        arrow = index(rest, "> ")
        if (arrow == 0) next
        where = substr(rest, 1, arrow - 1)
        what  = substr(rest, arrow + 2)

        if (n > 0) {
            d = (ts - prev_ts) * 1000
            # the DEBUG trap that keeps PS4 alive is our own instrumentation
            if (prev_where !~ /^TRAPDEBUG:/) {
                cost[prev_key] += d
                text[prev_key] = prev_text
                total += d
            }
        }
        colon = length(where)
        while (colon > 0 && substr(where, colon, 1) != ":") colon--
        file = (colon > 1) ? substr(where, 1, colon - 1) : where
        prev_key   = (mode == "xtrace") ? where : file
        prev_text  = what
        prev_where = where
        prev_ts    = ts
        n++
        next
    }
    END {
        if (n == 0) {
            print "trace-shell: no timestamped event -- PS4 was clobbered?" > "/dev/stderr"
            exit 1
        }
        home = ENVIRON["HOME"]
        i = 0
        for (k in cost) { i++; keys[i] = k }
        # plain insertion sort: a few dozen rows in source mode
        for (a = 2; a <= i; a++) {
            v = keys[a]
            for (b = a - 1; b >= 1 && cost[keys[b]] < cost[v]; b--) keys[b + 1] = keys[b]
            keys[b + 1] = v
        }
        shown = 0
        for (a = 1; a <= i && shown < top; a++) {
            k = keys[a]
            if (k ~ /\/END$/) continue
            label = k
            sub("^" home, "~", label)
            printf "  %8.2f ms  %5.1f%%  %s", cost[k], cost[k] * 100 / total, label
            if (mode == "xtrace") {
                t = text[k]
                if (length(t) > 60) t = substr(t, 1, 57) "..."
                printf "  %s", t
            }
            print ""
            shown++
        }
        printf "\n  %8.2f ms  total (sourcing window only, ends when ~/.zshrc returns)\n", total
    }
' "$log"
