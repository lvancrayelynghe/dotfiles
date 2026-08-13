# Dotfiles

Personal public dotfiles: zsh, bash, git, vim, tmux, Ghostty, Hammerspoon,
Sublime Text, VS Code, Claude Code — managed with
[dotter](https://github.com/SuperCuber/dotter) (Rust, single static binary).

## Install

```sh
brew install dotter   # Linux: static binary from the dotter releases page
git clone https://github.com/lvancrayelynghe/dotfiles.git ~/.dotfiles/public
cd ~/.dotfiles/public
./install
```

`./install` is idempotent: it (re)creates the symlinks declared in
`.dotter/global.toml` for the packages this machine enables in
`.dotter/local.toml` (auto-generated on first run: `common` + `macos` on
a Mac, `common` on Linux servers, add `linux-desktop` by hand), removes
links dropped from the config, then installs the zsh plugins, the pure
prompt, vim-plug and the Claude Code statusline. Re-run it any time.

### macOS extras

```sh
brew bundle              # install packages, apps and fonts (see Brewfile)
./macos-defaults.sh mbp  # system preferences (hostname optional)
```

### Linux servers

Only the shell/CLI configs matter there; `./install` skips the macOS-only
links automatically. Minimal packages:

```sh
apt install zsh git vim tmux curl ripgrep fzf eza zoxide bat fd-find jq
apt install du-dust duf sd   # names differ from the binaries: dust, duf, sd
```

The second line is not optional: the shared aliases route `du`, `df` and
`find-and-replace` through those three. Toolchain versions come from
[mise](https://mise.jdx.dev), which reads the versioned `mise/config.toml`.

## Layout

| Path | Purpose |
|---|---|
| `.dotter/global.toml` | all symlink mappings, grouped by package (dotter) |
| `install` | wrapper: `dotter deploy` + install hooks |
| `shell/aliases.sh` | entry point for the aliases shared by bash **and** zsh |
| `shell/aliases-*.sh` | the rest, split by topic (git, docker, dev, net) and by OS |
| `zsh/` | zsh config: `zshenv` → `zprofile` (PATH, env) → `zshrc` (interactive) |
| `bash/` | thin bash config sourcing `shell/aliases.sh` |
| `others/` | tool configs linked into `$HOME` (git, tmux, nano, less…) |
| `mise/` | global toolchain versions (node, claude, gemini) |
| `scripts/` | helper scripts (`install-zsh-plugins.sh`, `link-sublime.sh`…) |
| `claude/` | Claude Code statusline + merge-based installer |
| `Brewfile` | macOS packages (`brew bundle`) |
| `macos-defaults.sh` | macOS system preferences |

Per-tool directories (`ghostty/`, `lla/`, `ranger/`, `vim/`, `hammerspoon/`,
`sublime-text/`, `vscode/`, `rectangle/`) each hold that tool's own config.

## Machine-local overrides (never committed)

- `~/.zshrc_local`, `~/.zshrc_$HOST` — sourced by `zsh/zshrc` if present
- `~/.bashrc_local` — sourced by `bash/bashrc` if present

Put machine-specific PATH entries, aliases and tokens there. Toolchain versions
do **not** belong here any more: they live in `mise/config.toml`, versioned.

Annotated starting points — **copy them, never symlink them**, so that editing
the real file can never write back into this public repo:

```sh
cp zsh/zshrc_local.example ~/.zshrc_local
cp bash/bashrc_local.example ~/.bashrc_local
```

They are deliberately absent from `.dotter/global.toml`: an unmapped file here
is the intent, not an oversight.
