#!/usr/bin/env bash
#
# Copies every mode = "copy" dotfile FROM its live location BACK INTO the repo
# — the reverse of `mise bootstrap dotfiles apply`. These files cannot be
# symlinked (e.g. Rectangle rejects a symlinked config), so changes made in the
# app land only in the live copy; this captures them so they can be committed.
#
# The list is read from mise itself (`dotfiles status -J`), so any future
# mode = "copy" entry is picked up automatically — there is no second list to
# keep in sync. It only ever writes into the repo; live files are never touched.
# Review the result with `git diff` and commit.
set -euo pipefail

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles/public}"

# Same profile selection as ./install: platform files (Rectangle lives in the
# macOS profile) are only visible to `dotfiles status` under the right -E env.
case "$(uname)" in
    Darwin) profile=macos ;;
    Linux)  profile=linux ;;
    *)      echo "Unsupported platform: $(uname)" >&2; exit 1 ;;
esac

command -v mise >/dev/null 2>&1 || { echo "mise not installed" >&2; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "jq not installed" >&2; exit 1; }

# Capture into a variable first so a mise failure aborts here (set -e) instead
# of silently feeding an empty loop through the process substitution below.
status_json="$(mise -C "$DOTFILES_PATH" -E "$profile" bootstrap dotfiles status -J)"

changed=0
# Each entry is {target, source, mode, state}; keep the copies. Paths use ~ and
# the source may contain /../ — both resolve once ~ is expanded and cp runs.
while IFS=$'\t' read -r target source; do
    [ -n "$target" ] || continue
    live="${target/#"~"/$HOME}"
    repo="${source/#"~"/$HOME}"
    if [ ! -e "$live" ]; then
        echo "skip (no live file yet): $target"
        continue
    fi
    if cmp -s "$live" "$repo"; then
        continue
    fi
    cp "$live" "$repo"
    echo "backed up: $target"
    changed=1
done < <(printf '%s' "$status_json" \
    | jq -r '.files[] | select(.mode=="copy") | [.target, .source] | @tsv')

if [ "$changed" -eq 0 ]; then
    echo "All copy-mode dotfiles already match the repo, nothing to back up."
else
    echo "Done — review with 'git diff' and commit."
fi
