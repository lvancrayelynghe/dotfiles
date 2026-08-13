#!/usr/bin/env bash
#
# Installs or updates the external zsh plugins, the pure prompt and vim-plug.
# Called by ./install; safe to re-run at any time.
set -euo pipefail

PLUGINS_PATH="$HOME/.cache/zsh-plugins"

clone_or_update() {
    local repo="$1" dest="$2"
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --quiet --ff-only || true
    else
        rm -rf "$dest"
        git clone --quiet --depth 1 "https://github.com/$repo.git" "$dest"
    fi
}

mkdir -p "$PLUGINS_PATH"
clone_or_update zsh-users/zsh-syntax-highlighting "$PLUGINS_PATH/zsh-syntax-highlighting"
clone_or_update zsh-users/zsh-autosuggestions "$PLUGINS_PATH/zsh-autosuggestions"
clone_or_update sindresorhus/pure "$PLUGINS_PATH/pure"

# Expose pure under the names promptinit expects (see zsh/plugins.zsh)
mkdir -p "$PLUGINS_PATH/pure/symlinks"
ln -sfn "$PLUGINS_PATH/pure/pure.zsh" "$PLUGINS_PATH/pure/symlinks/prompt_pure_setup"
ln -sfn "$PLUGINS_PATH/pure/async.zsh" "$PLUGINS_PATH/pure/symlinks/async"

# vim-plug (plugin manager used by vim/vimrc)
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "zsh plugins up to date in $PLUGINS_PATH"
