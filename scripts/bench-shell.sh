#!/usr/bin/env bash
#
# Measures the user-visible latency of the interactive zsh with zsh-bench
# (https://github.com/romkatv/zsh-bench) and checks it against this repo's
# ceilings. Answers "is the shell fast enough for a human?" -- for "where does
# the time go?", use scripts/trace-shell.sh.
#
# Dev-only tool, on purpose:
#   - not in the Brewfile: upstream ships no formula and no tag,
#   - not in ./install: install-zsh-plugins.sh pulls unconditionally, which
#     would advance master under the recorded baseline and move the numbers,
#   - not in the pre-commit hook: a run costs ~35 s.
# Hence the clone pinned to a SHA below.
set -euo pipefail

ZSH_BENCH_REF="${ZSH_BENCH_REF:-28b1b1bc888159f0a2cf50f9d29381758341aba1}"
ZSH_BENCH_DIR="${ZSH_BENCH_DIR:-$HOME/.cache/zsh-bench}"
ZSH_BENCH_ITERS="${ZSH_BENCH_ITERS:-16}"
ZSH_BENCH_TIMEOUT="${ZSH_BENCH_TIMEOUT:-300}"

# Ceilings in ms. These are regression guards, not targets: they sit ~25% above
# the reference measurement recorded in CLAUDE.md. Two of them are already well
# past the perception thresholds printed alongside — that is the known state of
# the config, and moving those numbers is a separate job from guarding them.
# A slower box needs its own ceilings:
#   MAX_FIRST_PROMPT_LAG=400 MAX_COMMAND_LAG=60 scripts/bench-shell.sh
MAX_FIRST_PROMPT_LAG="${MAX_FIRST_PROMPT_LAG:-170}"
MAX_FIRST_COMMAND_LAG="${MAX_FIRST_COMMAND_LAG:-185}"
MAX_COMMAND_LAG="${MAX_COMMAND_LAG:-28}"
MAX_INPUT_LAG="${MAX_INPUT_LAG:-6}"
MAX_EXIT_TIME="${MAX_EXIT_TIME:-130}"

usage() {
    cat <<'EOF'
usage: scripts/bench-shell.sh [-n ITERS]

Runs zsh-bench against the live zsh config and compares the latencies to the
ceilings documented in CLAUDE.md. Exits non-zero if any ceiling is exceeded.

Environment overrides:
  ZSH_BENCH_ITERS, ZSH_BENCH_TIMEOUT, ZSH_BENCH_DIR, ZSH_BENCH_REF
  MAX_FIRST_PROMPT_LAG, MAX_FIRST_COMMAND_LAG, MAX_COMMAND_LAG,
  MAX_INPUT_LAG, MAX_EXIT_TIME
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--iters) ZSH_BENCH_ITERS="${2:?-n needs a value}"; shift 2 ;;
        -h|--help)  usage; exit 0 ;;
        *)          usage >&2; exit 2 ;;
    esac
done

# awk reads a non-numeric ceiling as 0, which would turn its gate green instead
# of failing: validate before anything can silently pass.
for _v in MAX_FIRST_PROMPT_LAG MAX_FIRST_COMMAND_LAG MAX_COMMAND_LAG \
          MAX_INPUT_LAG MAX_EXIT_TIME ZSH_BENCH_ITERS ZSH_BENCH_TIMEOUT; do
    case "${!_v}" in
        ''|*[!0-9]*|0)
            echo "bench-shell: $_v must be a positive integer (got '${!_v}')" >&2
            exit 2 ;;
    esac
done
unset _v

zsh_bin="$(command -v zsh || true)"
if [ -z "$zsh_bin" ]; then
    echo "bench-shell: zsh is required" >&2
    exit 1
fi

# Pin the harness. A moving master silently invalidates the recorded baseline.
if [ -d "$ZSH_BENCH_DIR/.git" ]; then
    if [ "$(git -C "$ZSH_BENCH_DIR" rev-parse HEAD 2>/dev/null || true)" != "$ZSH_BENCH_REF" ]; then
        git -C "$ZSH_BENCH_DIR" fetch --quiet origin
        git -C "$ZSH_BENCH_DIR" checkout --quiet "$ZSH_BENCH_REF"
    fi
else
    rm -rf "$ZSH_BENCH_DIR"
    git clone --quiet https://github.com/romkatv/zsh-bench.git "$ZSH_BENCH_DIR"
    git -C "$ZSH_BENCH_DIR" checkout --quiet "$ZSH_BENCH_REF"
fi

# zsh-bench runs its payload through $SHELL. On Linux (util-linux `script -c`)
# a non-zsh $SHELL does not produce an error -- it hangs forever with no output
# at all. Force it, and keep a timeout so the failure mode stays bounded.
runner=(env "SHELL=$zsh_bin")
for t in timeout gtimeout; do
    if command -v "$t" >/dev/null 2>&1; then
        runner+=("$t" "$ZSH_BENCH_TIMEOUT")
        break
    fi
done

echo "zsh-bench ${ZSH_BENCH_REF:0:7} — $ZSH_BENCH_ITERS iterations, login shell, in a git repo"

# Keep zsh-bench's stderr rather than dropping it: on success it is only the
# progress banner, on failure it is the entire diagnosis (wrong zsh version,
# "cannot find prompt", a broken `script`).
err="$(mktemp "${TMPDIR:-/tmp}/bench-shell.XXXXXX")"
trap 'rm -f "$err"' EXIT

rc=0
out="$("${runner[@]}" "$ZSH_BENCH_DIR/zsh-bench" --iters "$ZSH_BENCH_ITERS" 2>"$err")" || rc=$?
if [ "$rc" -ne 0 ]; then
    cat "$err" >&2
    [ -z "$out" ] || printf '%s\n' "$out" >&2
    if [ "$rc" -eq 124 ]; then
        echo "bench-shell: zsh-bench timed out after ${ZSH_BENCH_TIMEOUT}s" >&2
        echo "  on Linux this usually means \$SHELL is not zsh inside the run" >&2
        exit 1
    fi
    echo "bench-shell: zsh-bench failed (exit $rc)" >&2
    exit "$rc"
fi

printf '%s\n' "$out" | awk \
    -v max_fpl="$MAX_FIRST_PROMPT_LAG" \
    -v max_fcl="$MAX_FIRST_COMMAND_LAG" \
    -v max_cl="$MAX_COMMAND_LAG" \
    -v max_il="$MAX_INPUT_LAG" \
    -v max_et="$MAX_EXIT_TIME" '
    /^[a-z_]+=/ { split($0, kv, "="); v[kv[1]] = kv[2]; next }

    function row(key, ceiling, perception,    val, gate, feel) {
        val = v[key] + 0
        gate = (val <= ceiling) ? "ok" : "OVER"
        if (gate == "OVER") failed++
        if (perception > 0)
            feel = sprintf("%6d %5d%%  %s", perception, val * 100 / perception,
                           (val <= perception) ? "ok" : "over")
        else
            feel = sprintf("%6s %6s  %s", "-", "-", "-")
        printf "  %-22s %8.1f %8d  %-4s   %s\n", key, val, ceiling, gate, feel
    }

    END {
        if (!("first_prompt_lag_ms" in v)) {
            print "bench-shell: no metric in the zsh-bench output" > "/dev/stderr"
            exit 1
        }
        # zsh-bench keeps the minimum over the iterations, not a median: a run
        # with fewer iterations reads as a regression against a 16-iter number.
        print ""
        printf "  %-22s %8s %8s  %-4s   %6s %6s  %s\n", \
               "metric", "min", "ceiling", "gate", "human", "of it", ""
        row("first_prompt_lag_ms",  max_fpl, 50)
        row("first_command_lag_ms", max_fcl, 150)
        row("command_lag_ms",       max_cl,  10)
        row("input_lag_ms",         max_il,  20)
        row("exit_time_ms",         max_et,  0)
        print ""
        printf "  capabilities: compsys=%s highlighting=%s autosuggestions=%s git_prompt=%s tty=%s\n", \
               v["has_compsys"], v["has_syntax_highlighting"], \
               v["has_autosuggestions"], v["has_git_prompt"], v["creates_tty"]
        # Two zeroes on that line are expected, not regressions:
        #   git_prompt=0     pure resolves the branch asynchronously, so it is
        #                    absent from the first prompt by design.
        #   highlighting=0   zsh-bench probes for the variables set by
        #                    zsh-syntax-highlighting and fast-syntax-highlighting
        #                    (ZSH_HIGHLIGHT_VERSION / FAST_HIGHLIGHT_VERSION)
        #                    rather than testing the rendered line, and
        #                    zsh-patina sets neither. input_lag_ms is where the
        #                    highlighter shows up: ~1.8 ms with none loaded,
        #                    ~3.6 ms with patina, ~10.4 ms with the plugin it
        #                    replaced.
        print ""
        if (failed) {
            printf "  %d ceiling(s) exceeded\n", failed
            exit 1
        }
        print "  all ceilings met"
    }
'
