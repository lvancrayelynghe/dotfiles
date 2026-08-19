#!/usr/bin/env bash
#
# Installs the gh CLI extensions. Called by ./install; safe to re-run at any time.
set -euo pipefail

# One line per extension: the "owner/repo" gh expects, not the command name.
EXTENSIONS=(
    dlvhdr/gh-dash # `gh dash`: PR / issue / notification dashboard (TUI)
)

# gh is a mise-managed portable tool and can still be absent before bootstrap:
# skip rather than fail, ./install runs everywhere.
if ! command -v gh >/dev/null 2>&1; then
    echo "gh not installed, no extension to install"
    exit 0
fi

for repo in "${EXTENSIONS[@]}"; do
    # Re-running is free: gh checks its extension directory first, prints
    # "! Extension <repo> is already installed" and still exits 0 -- no network
    # call, so no pre-check to write here. The install itself is an anonymous
    # release download: it works before `gh auth login`, unlike most of gh.
    # Extensions are never upgraded here (that would refetch on every deploy);
    # do it by hand with `gh extension upgrade --all`.
    gh extension install "$repo" || echo "  [gh] $repo: install failed" >&2
done
