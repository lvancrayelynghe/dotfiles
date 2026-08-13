# CLAUDE.md

## Repository nature

**Public** dotfiles (github.com/lvancrayelynghe/dotfiles). Absolute rules:

- **Never any secret, token, password, internal hostname, or runtime state**
  in this repo. Anything sensitive stays local.
- Files are **symlinked in place** in `$HOME` via dotter: editing
  `~/.zshrc`, `~/.gitconfig`, etc. directly modifies this repo. Never
  do `echo >> ~/.zshrc` from a script — it pollutes the versioned file
  (the historical cause of duplicate PATH entries).
- `vscode/settings.json` is symlinked: VS Code automatically rewrites
  some keys there. **Never commit the `remote.SSH.*` keys** (`remotePlatform`
  lists the hostnames of every Remote-SSH connection — including client
  servers). Remove them from the diff before any commit.

## Architecture

- `.dotter/global.toml` — **any new config file must be mapped here**
  (in the appropriate package: `common`, `macos`, or `linux-desktop`; each
  machine enables its own via `.dotter/local.toml`, which is never committed).
  `./install` is idempotent and reruns `dotter deploy --force`.
- `shell/aliases.sh` — source of truth for aliases **shared between bash and
  zsh**. POSIX-compatible syntax only (no `alias -g`, no zsh arrays).
  zsh-specific aliases go in `zsh/aliases.zsh`.
- zsh load order: `zshenv` (always) → `zprofile` (login: PATH,
  MANPATH, EDITOR, `typeset -U path`) → `zshrc` (interactive) →
  `zsh/*.zsh` files → `~/.zshrc_$HOST` / `~/.zshrc_local` (machine-local,
  never committed).
- `zsh/plugins.zsh` only **sources** the plugins; their network
  installation lives in `scripts/install-zsh-plugins.sh` (a hook of
  `./install`). Never any network command or extra `compinit` in the
  startup files.
- `claude/install.sh` (atomic jq merge into `~/.claude/settings.json`) is
  the model for any hook that needs to merge rather than overwrite.

## Compatibility constraints

- **Dual target: macOS (BSD userland) and Linux (LEMP servers)**. Keep the
  `$OSTYPE`/`uname` branches. On macOS, GNU tools are prefixed with `g`
  (gls, gsed, ggrep — aliased in `shell/aliases.sh`).
- `bash/profile` must remain POSIX sh (read by dash on Debian/Ubuntu).
- `others/gitconfig` must stay compatible with the older git versions on
  the servers; macOS-only options go in `others/gitconfig-macos`
  (loaded via `includeIf "gitdir:/Users/"`).
- Shell startup budget: `time zsh -i -c exit` must stay **under 200 ms**
  (measured ~90 ms). Any costly addition must be lazy-loaded or cached.

## Pre-commit checks

```sh
zsh -n <file.zsh>             # zsh syntax
bash -n <file.sh>             # bash syntax (shell/aliases.sh must pass both)
shellcheck scripts/*.sh       # lint the scripts
./install                     # must remain idempotent (zero prompts, re-runnable)
time zsh -i -c exit           # budget < 200 ms
brew bundle check             # Brewfile consistency (macOS)
luac -p hammerspoon/**/*.lua  # Lua syntax
tmux -f others/tmux.conf -L test new -d \; kill-server  # parse tmux.conf
```

## Style

- Commits: short imperative, in English, one concern per commit
  (see `git log`). Large changes on a dedicated branch, never
  directly on `master`.
- 4-space indentation (`.editorconfig`).
