#!/usr/bin/env bash
#
# Links the Sublime Text configuration into the active data directory.
# Called by ./install; safe to re-run.
#
# Sublime Text 4 uses "Sublime Text" but keeps using a pre-existing
# "Sublime Text 3" directory (upgrade compatibility). We link into whichever
# is active. Once Sublime is closed, the old directory can be migrated with:
#   mv "$HOME/Library/Application Support/Sublime Text 3" \
#      "$HOME/Library/Application Support/Sublime Text"
# then re-run ./install.
set -euo pipefail

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles/public}"
SRC="$DOTFILES_PATH/sublime-text/Packages"

case "$(uname)" in
    Darwin)
        if [ -d "$HOME/Library/Application Support/Sublime Text" ]; then
            DATA_DIR="$HOME/Library/Application Support/Sublime Text"
        elif [ -d "$HOME/Library/Application Support/Sublime Text 3" ]; then
            DATA_DIR="$HOME/Library/Application Support/Sublime Text 3"
        else
            echo "Sublime Text data directory not found, skipping"
            exit 0
        fi
        ;;
    *)
        if [ -d "$HOME/.config/sublime-text" ]; then
            DATA_DIR="$HOME/.config/sublime-text"
        elif [ -d "$HOME/.config/sublime-text-3" ]; then
            DATA_DIR="$HOME/.config/sublime-text-3"
        else
            echo "Sublime Text data directory not found, skipping"
            exit 0
        fi
        ;;
esac

mkdir -p "$DATA_DIR/Packages/User"

# Whole directories
for dir in CommandOnSave PHP Snippets; do
    ln -sfn "$SRC/$dir" "$DATA_DIR/Packages/$dir"
done
ln -sfn "$SRC/ChromeRemoteReload.py" "$DATA_DIR/Packages/ChromeRemoteReload.py"

# User files
for file in "$SRC/User/"*; do
    name="$(basename "$file")"
    # The keymap is suffixed per-OS in the repo
    case "$name" in
        Default.sublime-keymap.mac)
            [ "$(uname)" = Darwin ] && ln -sfn "$file" "$DATA_DIR/Packages/User/Default.sublime-keymap"
            continue ;;
        Default.sublime-keymap.pc)
            [ "$(uname)" != Darwin ] && ln -sfn "$file" "$DATA_DIR/Packages/User/Default.sublime-keymap"
            continue ;;
    esac
    ln -sfn "$file" "$DATA_DIR/Packages/User/$name"
done

echo "Sublime Text config linked into $DATA_DIR"
