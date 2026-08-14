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
- `shell/aliases.sh` — **entry point** for the aliases shared between bash and
  zsh, and home of the general-purpose ones. It sources the per-topic files at
  the bottom; callers still source this one file only. POSIX-compatible syntax
  throughout (no `alias -g`, no zsh arrays). zsh-only aliases, including the
  global pipe ones, go in `zsh/aliases.zsh`.
  - `aliases-git.sh`, `aliases-docker.sh`, `aliases-dev.sh`, `aliases-net.sh` —
    by topic. A new docker alias goes in the docker file, not the entry point.
  - `aliases-macos.sh`, `aliases-linux.sh` — everything OS-specific, **by
    filename rather than by `$OSTYPE` branch**.
  - **The OS file is sourced last, on purpose**: on macOS it replaces the
    generic `grep` aliases with the GNU ones. Anything that must see the plain
    tools has to be defined before it — a function body captures alias
    expansions when it is *defined*, which is why the disk usage block sits
    where it does.
  - Everything after the `# >>> plumbing` marker is hidden from
    `cheat-sheet()`. That function also lists these files explicitly, so adding
    a topic file means updating it in `zsh/functions.zsh`.
- `ssh/config` + `ssh/config.d/` — the skeleton declares **no host**; they all
  live in `~/.ssh/config.d/`, of which only `10-forges`, `90-defaults` and
  `95-macos` belong here. `50-internes`, `60-clients` and `80-archives` are not
  part of this repo and hold every real hostname — **never add a host to the
  versioned files**. Three rules govern this layout:
  - ssh keeps the **first** value it obtains for a keyword, never the last,
    hence the numbering: host files (10/50/60/80) must be read *before* the
    `Host *` defaults (90/95). A host added above 90 would silently lose.
  - `IgnoreUnknown` obeys that same rule, so there is exactly **one**
    declaration, in `ssh/config` before any `Include`. A second one anywhere
    would be discarded and the keyword it covers would abort ssh with
    `Bad configuration option`. It shields `UseKeychain`/`WarnWeakCrypto`
    (Apple-only, hence the `macos` package) and `SetEnv`/`AddKeysToAgent`
    (too recent for the oldest servers).
  - An `Include` that resolves to nothing — missing file, missing directory,
    unmatched glob — is a **silent** no-op, which is what lets one versioned
    skeleton work everywhere. `ssh -v` reports `matched no files`, and
    `ssh -G <host>` prints the resolved config without connecting.
- `mise/config.toml` — global toolchain versions (node, claude, gemini),
  symlinked like the rest, so `mise use -g` edits the versioned file.
- `hammerspoon/` — `macos` package, mapped as a **single directory symlink**
  (`recurse = false`): **any `.lua` saved there reloads the live config at
  once**, and a syntax error takes it down until the next save. That directory
  carries its own `CLAUDE.md`, loaded when a file in it is read, and holds the
  rest — the constraints there are many, and none of them are guessable.
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

- **Dual target: macOS (BSD userland) and Linux (LEMP servers)**. Prefer a
  per-OS file over an `$OSTYPE` branch; keep the branches that remain inside
  functions, where a file split cannot reach. On macOS, GNU tools are prefixed
  with `g` (gls, gsed, ggrep — aliased in `shell/aliases-macos.sh`, with the
  target backslash-quoted so the shell runs the binary instead of re-expanding
  it as an alias).
- The shared aliases now depend on `dust`, `duf` and `sd`, so a server needs
  them too — their distribution package names differ from the binaries.
- `bash/profile` must remain POSIX sh (read by dash on Debian/Ubuntu).
- `others/gitconfig` must stay compatible with the older git versions on
  the servers; macOS-only options go in `others/gitconfig-macos`
  (loaded via `includeIf "gitdir:/Users/"`).
- Shell startup budget: `time zsh -i -c exit` must stay **under 200 ms**
  (measured ~80 ms, with a real spread under load — measure several times).
  Any costly addition must be lazy-loaded or cached: `fzf` and `mise` both
  generate their init script into `~/.cache`, regenerated only when the binary
  is newer, because each of them forks otherwise.

## Pre-commit checks

A hook enforces part of this. `others/git-templates/hooks/pre-commit` refuses a
commit whose **added** lines carry a private key, a password assignment, a
VS Code Remote-SSH host list or a provider token; `./install` points
`core.hooksPath` at it, since `init.templateDir` only seeds new repositories.
`others/my.cnf` is an accepted path. Bypass with `git commit --no-verify`.

```sh
zsh -n <file.zsh>             # zsh syntax
bash -n <file.sh>             # bash syntax (shell/aliases*.sh must pass both)
shellcheck install scripts/*.sh others/git-templates/hooks/pre-commit
./install                     # must remain idempotent (zero prompts, re-runnable)
time zsh -i -c exit           # budget < 200 ms
brew bundle check --no-upgrade --verbose   # declared but missing
brew bundle cleanup           # installed but undeclared (dry run; --force removes)
luac -p hammerspoon/**/*.lua  # Lua syntax
for t in hammerspoon/tests/*.lua; do lua "$t" || break; done  # stub hs suites
tmux -f others/tmux.conf -L test new -d \; kill-server  # parse tmux.conf
```

Nothing runs these automatically, and the Linux half of the config is
validated by inspection only — with one exception: the `ssh/` files were
parsed against OpenSSH 9.2 in a Debian 12 container, which confirmed that a
stray `95-macos.conf` there is harmless *because of* the `IgnoreUnknown`, and
fatal without it. A container is the way to check any other Linux-only claim:

```sh
ssh -G <host>                        # resolved ssh config, connects to nothing
docker run --rm -v "$PWD/ssh:/cfg:ro" debian:12 sh -c \
    'apt-get update -qq && apt-get install -y -qq openssh-client && \
     mkdir -p ~/.ssh/config.d && cp /cfg/config ~/.ssh/ && \
     cp /cfg/config.d/[19]*.conf ~/.ssh/config.d/ && \
     chmod 600 ~/.ssh/config ~/.ssh/config.d/*.conf && ssh -G github.com'
```

## Style

- Commits: short imperative, in English, one concern per commit
  (see `git log`). Large changes on a dedicated branch, never
  directly on `master`.
- 4-space indentation (`.editorconfig`).
