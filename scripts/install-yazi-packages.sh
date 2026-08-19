#!/usr/bin/env bash
#
# Installs the yazi flavors/plugins declared in ~/.config/yazi/package.toml
# (symlinked from yazi/package.toml). Run by the mise bootstrap task; safe to
# re-run at any time.
set -euo pipefail

# ya ships with yazi, a mise-managed portable tool, and can be absent before
# bootstrap: skip rather than fail, ./install runs everywhere.
if ! command -v ya >/dev/null 2>&1; then
    echo "yazi (ya) not installed, no package to install"
    exit 0
fi

# Reads the versioned package.toml and clones each pinned flavor/plugin into
# ~/.config/yazi/flavors (runtime state, not versioned). Idempotent in result,
# but note it re-fetches and redeploys the pinned rev on every run (a network
# fetch each time, not a skip like gh's), leaving the flavors at package.toml.
# Nothing upgrades them here: `ya pkg upgrade` by hand.
ya pkg install
