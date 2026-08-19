# Dotfiles

Personal public dotfiles: zsh, bash, git, vim, Ghostty, Hammerspoon,
Sublime Text, VS Code and Claude Code — bootstrapped with
[mise](https://mise.jdx.dev).

## Install

```sh
git clone https://github.com/lvancrayelynghe/dotfiles.git ~/.dotfiles/public
cd ~/.dotfiles/public
./install
```

`./install` installs mise with its official installer if needed, trusts this
reviewed checkout locally, then runs `mise bootstrap`. It converges the
dotfile links, platform packages and versioned CLI tools before running the
idempotent integrations for zsh, vim, gh, Sublime Text and Claude Code.
Re-run it any time. Existing real files are deliberately not overwritten: pass
`--force-dotfiles` only after inspecting the conflict mise reports.

On a Linux desktop, copy `mise/config.local.toml.example` to the ignored
`mise/config.local.toml` before running `./install`; it adds the VS Code links.
Linux servers use the common + Linux configuration only.

### macOS extras

```sh
mise run macos-defaults           # system preferences (mise task)
./macos-defaults.sh "My MacBook"  # …or run directly to also set the computer name
```

Applications, fonts, CLI packages and Mac App Store entries are declared in
`mise/config.macos*.toml`; `./install` applies them. mise uses its built-in
Homebrew package manager and does not require `brew bundle` or a `Brewfile`.
On an existing Homebrew workstation, mise deliberately does not take ownership
of casks: `./install` deploys the rest and prints the explicit apps-migration
command. `libreoffice-language-pack` remains a manual exception, because its
cask script is not currently supported by mise.

`macos-defaults.sh` is exposed as the `macos-defaults` mise task but is
deliberately not part of `mise bootstrap` / `./install`: every line writes a
system preference, so it is run by hand, once, on a fresh install —
never to check something. The optional argument sets `ComputerName` verbatim
and derives `LocalHostName` from a sanitised copy (the Bonjour name accepts
neither spaces nor accents); `HostName` is deliberately left unset so macOS
keeps deriving it from the network. Read the file first: the commented-out
lines are settings deliberately left at the macOS default, and uncommenting one
is an opt-in.

### Linux servers

`./install` selects the Linux profile, which delegates native dependencies to
apt and installs portable CLIs through mise. The shared aliases therefore get
`dust`, `duf` and `sd` without a hand-maintained apt command.

## Layout

| Path | Purpose |
|---|---|
| `mise/config.toml` | shared tools, symlink mappings and bootstrap task |
| `mise/config.macos.toml` | macOS native packages and dotfiles |
| `mise/config.macos-apps.toml` | macOS applications, fonts and App Store entries |
| `mise/config.linux.toml` | Debian/Ubuntu native dependencies |
| `install` | mise bootstrap wrapper |
| `shell/aliases.sh` | entry point for the aliases shared by bash **and** zsh |
| `shell/aliases-*.sh` | the rest, split by topic (git, docker, dev, net) and by OS |
| `zsh/` | zsh config: `zshenv` → `zprofile` (PATH, env) → `zshrc` (interactive) |
| `bash/` | thin bash config sourcing `shell/aliases.sh` |
| `others/` | tool configs linked into `$HOME` (git, nano, less…) |
| `ssh/` | `~/.ssh/config` skeleton + the public half of `config.d/` |
| `mise/` | global toolchain, packages, dotfiles and bootstrap configuration |
| `scripts/` | helper scripts (`install-zsh-plugins.sh`, `link-sublime.sh`…) |
| `scripts/bench-shell.sh` | interactive zsh latency, via [zsh-bench](https://github.com/romkatv/zsh-bench) |
| `scripts/trace-shell.sh` | where zsh startup time goes, per sourced file or per line |
| `claude/` | Claude Code statusline + merge-based installer |
| `macos-defaults.sh` | macOS system preferences — `mise run macos-defaults`, by hand, never by `./install` |

Per-tool directories (`ghostty/`, `lla/`, `ranger/`, `vim/`, `hammerspoon/`,
`sublime-text/`, `vscode/`, `rectangle/`) each hold that tool's own config.

## Machine-local overrides (never committed)

- `~/.zshrc_local`, `~/.zshrc_$HOST` — sourced by `zsh/zshrc` if present
- `~/.bashrc_local` — sourced by `bash/bashrc` if present
- `~/.ssh/config.d/50-internes.conf`, `60-clients.conf`, `80-archives.conf` —
  every real host, and deliberately absent from this repo. `~/.ssh/config` is
  versioned here but declares none: it only includes `config.d/*.conf`, and an
  include that matches nothing is a silent no-op, so a machine without those
  three files works fine.

Put machine-specific PATH entries, aliases and tokens there. Toolchain versions
and managed system packages live in the versioned `mise/config*.toml` files.

Annotated starting points — **copy them, never symlink them**, so that editing
the real file can never write back into this public repo:

```sh
cp zsh/zshrc_local.example ~/.zshrc_local
cp bash/bashrc_local.example ~/.bashrc_local
```

They are deliberately absent from `[dotfiles]`: an unmanaged file here is the
intent, not an oversight.
