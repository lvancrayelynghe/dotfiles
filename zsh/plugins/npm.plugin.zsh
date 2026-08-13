#!/usr/bin/env zsh

# Global npm packages installed in the home directory (prefix=~/.npm-packages
# in ~/.npmrc). Only wired up when that layout is actually in use.

NPM_PACKAGES="${HOME}/.npm-packages"

if [[ -d "$NPM_PACKAGES" ]]; then
    path=("$NPM_PACKAGES/bin" $path)
    # The trailing colon keeps the system default man search path
    export MANPATH="$NPM_PACKAGES/share/man:${MANPATH:-}"
fi
