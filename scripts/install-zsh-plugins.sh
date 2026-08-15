#!/usr/bin/env bash
#
# Installs or updates the external zsh plugins, the pure prompt and vim-plug.
# Called by ./install; safe to re-run at any time.
set -euo pipefail

PLUGINS_PATH="$HOME/.cache/zsh-plugins"

COMPLETIONS_PATH="$HOME/.cache/zsh-completions"

clone_or_update() {
    local repo="$1" dest="$2"
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --quiet --ff-only || true
    else
        rm -rf "$dest"
        git clone --quiet --depth 1 "https://github.com/$repo.git" "$dest"
    fi
}

# Move "$1.tmp" into place, dropping the compinit dump only when the content
# actually changed: compinit -C trusts that dump for 24h and would not see a
# new $fpath file before it expires.
install_completion() {
    local dest="$1"
    if cmp -s "$dest.tmp" "$dest" 2>/dev/null; then
        rm -f "$dest.tmp"
    else
        mv "$dest.tmp" "$dest"
        rm -f "$HOME/.cache/zsh-completion-dump"
    fi
}

mkdir -p "$PLUGINS_PATH"
# Syntax highlighting is zsh-patina, a binary from Homebrew (macOS) or the .deb
# (Debian) rather than a clone -- see zsh/plugins.zsh. Drop the clone it
# replaced so the cache does not keep a repo nothing sources any more.
rm -rf "$PLUGINS_PATH/zsh-syntax-highlighting"
clone_or_update zsh-users/zsh-autosuggestions "$PLUGINS_PATH/zsh-autosuggestions"
clone_or_update sindresorhus/pure "$PLUGINS_PATH/pure"

# Expose pure under the names promptinit expects (see zsh/plugins.zsh)
mkdir -p "$PLUGINS_PATH/pure/symlinks"
ln -sfn "$PLUGINS_PATH/pure/pure.zsh" "$PLUGINS_PATH/pure/symlinks/prompt_pure_setup"
ln -sfn "$PLUGINS_PATH/pure/async.zsh" "$PLUGINS_PATH/pure/symlinks/async"

# Homebrew ships television's zsh completion as the output of `tv init zsh` --
# the *shell integration*, whose last two lines are `bindkey '^T'`/`bindkey '^R'`.
# Autoloading it, which one `tv <TAB>` does, steals both keys from fzf. `tv
# completions zsh` is the completion alone, no widget and no bindkey: generate
# that into the cache dir, which zsh/completion.zsh puts ahead of Homebrew's
# in $fpath.
if command -v tv >/dev/null 2>&1; then
    mkdir -p "$COMPLETIONS_PATH"
    tv completions zsh > "$COMPLETIONS_PATH/_tv.tmp"

    # Its CHANNEL argument is generated with the `_default` action, so `tv <TAB>`
    # offers file names. Point it at _tv_channels instead, written just below and
    # autoloaded by compinit through that same $fpath entry (`#autoload` marker).
    if grep -q '::channel -- .*:_default' "$COMPLETIONS_PATH/_tv.tmp"; then
        sed 's|\(::channel -- [^:]*\):_default|\1:_tv_channels|' \
            "$COMPLETIONS_PATH/_tv.tmp" > "$COMPLETIONS_PATH/_tv.patched"
        mv "$COMPLETIONS_PATH/_tv.patched" "$COMPLETIONS_PATH/_tv.tmp"
    else
        echo "install-zsh-plugins: tv's CHANNEL action moved, channels left unwired" >&2
    fi
    install_completion "$COMPLETIONS_PATH/_tv"

    # `tv list-channels` costs under a millisecond, so no cache to invalidate
    cat > "$COMPLETIONS_PATH/_tv_channels.tmp" <<'EOF'
#autoload

local -a channels
channels=(${(f)"$(tv list-channels 2>/dev/null)"})
_describe -t channels channel channels
EOF
    install_completion "$COMPLETIONS_PATH/_tv_channels"
fi

# vim-plug (plugin manager used by vim/vimrc)
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
    curl -fsSLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

echo "zsh plugins up to date in $PLUGINS_PATH"
