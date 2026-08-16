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
  startup files. One exception to the sourcing rule: syntax highlighting is
  **zsh-patina**, a compiled binary driving a daemon shared by every session,
  so it is installed as a package (Brewfile / `.deb`) and activated with
  `eval "$(zsh-patina activate)"`, not cloned and sourced.
- `scripts/install-gh-extensions.sh` — the gh CLI extensions (another hook of
  `./install`), one array line per `owner/repo`. Not a Brewfile entry: gh only
  runs extensions found in its own data directory, so the Homebrew formula
  would give the binary and no `gh <command>`. Re-running is free and offline
  (gh checks that directory first, prints `already installed`, exits 0), and
  installing needs **no** `gh auth login` — it is an anonymous release
  download, unlike almost everything else gh does. Nothing upgrades them:
  `gh extension upgrade --all` by hand.
- `claude/install.sh` (atomic jq merge into `~/.claude/settings.json`) is
  the model for any hook that needs to merge rather than overwrite.
- `macos-defaults.sh` — **not mapped in dotter, not called by `./install`**:
  every line writes a system preference, so it is run by hand, once, on a fresh
  install. Never run it to inspect anything — read it, or read the machine with
  `defaults read <domain> <key>`. Regenerated 2026-08-15 from the live state of
  a MacBookPro18,3 on macOS 26.5, and three rules keep it readable: an active
  line reproduces a value the machine actually has, a commented-out line is a
  setting left at the macOS default (uncommenting is a deliberate opt-in), and
  a key that no longer exists is deleted rather than left to rot.
  - The 15 removed keys are listed at the bottom of the file with the method
    that condemned them, which has **two halves and needs both**. First, the
    name must be absent as a **standalone C literal** from the owning binary —
    both architecture slices, including strings inlined as x86_64 `movabs`
    immediates that `strings` cannot see — *and* from all twelve slices of the
    dyld shared cache. Then `defaults find <fragment>` must come up empty
    across the live domains, because a key assembled at runtime appears in no
    binary at all: `PMPrintingExpandedStateForPrint2` is built by appending the
    `2`, so only `defaults find` reveals that the unsuffixed name the old
    script wrote was the wrong one. Three traps in the binary half: inlined
    immediates (`mru-spaces`, `showhidden` are alive and look missing),
    substring matches (`SortColumn` hits inside `_updateSortColumn`), and
    immediate fragments that are *not* adjacent — `disable-shadow` and
    `DisableSendAnimations` both look inlined and are genuinely dead, so the
    `movabs` pair has to be checked for adjacency, not just presence.
  - Two failure modes the file comments rather than repeats: `-dict`
    **replaces** a dictionary where `-dict-add` merges (the old
    `FXInfoPanesExpanded` line silently dropped four panes), and the
    `com.apple.SoftwareUpdate` keys are read only from `/Library/Preferences`,
    so writing them to the user domain without `sudo` is a silent no-op.
  - The menu bar section reaches exactly two mechanisms: Control Center modules
    (ints in the **ByHost** domain, 18 shown / 8 hidden) and `NSStatusItem
    Visible <autosaveName>` in each app's own domain. The System Settings >
    Menu Bar switches are stored where no script can read them; the file lists
    what has to be redone by hand. A third-party app must be **quit** before
    its line runs, or cfprefsd rewrites the domain from its cache on exit.

## Compatibility constraints

- **Dual target: macOS (BSD userland) and Linux (LEMP servers)**. Prefer a
  per-OS file over an `$OSTYPE` branch; keep the branches that remain inside
  functions, where a file split cannot reach. On macOS, GNU tools are prefixed
  with `g` (gls, gsed, ggrep — aliased in `shell/aliases-macos.sh`, with the
  target backslash-quoted so the shell runs the binary instead of re-expanding
  it as an alias).
- The shared aliases now depend on `dust`, `duf` and `sd`, so a server needs
  them too — their distribution package names differ from the binaries.
- `zsh-patina` is a **binary**, and the only piece of the zsh startup that is
  not either versioned here or cloned by `install-zsh-plugins.sh`. macOS gets
  it from the Brewfile; Debian has **no apt repository** — grab the `.deb`
  (`amd64`/`arm64`, plus musl builds) from the releases page and `dpkg -i` it.
  Its absence is not fatal: `zsh/plugins.zsh` guards on `command -v`, so a
  server without it simply has no highlighting.
- `bash/profile` must remain POSIX sh (read by dash on Debian/Ubuntu).
- `others/gitconfig` must stay compatible with the older git versions on
  the servers; macOS-only options go in `others/gitconfig-macos`
  (loaded via `includeIf "gitdir:/Users/"`).
- Shell latency is measured by two checks, because they answer different
  questions, and by no instrumentation left inside the startup files.
  - `time zsh -i -c exit` — **ceiling 130 ms** (measured ~100 ms, real spread
    under load, measure several times). Portable smoke test, and the only one a
    Debian server runs over ssh with nothing installed. It tracks the sourcing
    path closely — this config defers nothing, so a cost added to `zsh/zshrc`
    moves it roughly 1:1 — but it is **blind to everything after zshrc**:
    prompt, zle-init, `precmd` hooks. A 50 ms `precmd` hook moves `command_lag`
    by +68 ms and this metric by −0.5 ms. It also does not run the same code:
    under `-c` there is no zle, so mise emits `can't change option: zle` twice
    and zoxide skips its `[[ -o zle ]]` branch.
  - `scripts/bench-shell.sh` — zsh-bench in a pty, ~35 s, what is actually
    felt. Reference on the M-series Mac, **minimum** of 16 iterations (zsh-bench
    reports the min, not a median, so a short run is not comparable):
    `first_prompt_lag` 138, `first_command_lag` 150, `command_lag` 11.4,
    `input_lag` 3.6, `exit_time` 98 ms. The ceilings in the script sit ~25% above
    those — regression guards, not targets: against romkatv's perception
    thresholds (50 / 150 / 10 / 20 ms) `first_prompt_lag` is still ~2.5× over,
    `first_command_lag` sits right on its threshold, and `command_lag` now
    lands just above its own.
    `git_prompt=0` is expected, pure resolves the branch asynchronously, and so
    is `highlighting=0`: zsh-bench sniffs `ZSH_HIGHLIGHT_VERSION` /
    `FAST_HIGHLIGHT_VERSION` instead of testing the rendered line, and
    zsh-patina defines neither. `input_lag` is where a highlighter actually
    shows up, measured here A/B over 3 interleaved rounds of 16 iterations:
    **1.8 ms** with none loaded, **3.6 ms** with zsh-patina, **10.4 ms** with
    the zsh-syntax-highlighting it replaced — so its share of the budget drops
    ~5×. Nothing else moved: `command_lag` read ~19.4 ms in all three, so none
    of it was highlighting.
    That ~19.4 ms was then halved to **11.4 ms** by `ZSH_AUTOSUGGEST_MANUAL_REBIND`
    (see `zsh/plugins.zsh`): zsh-autosuggestions was rebinding 387 widgets on
    every prompt, ~8.9 ms of it. Only the remainder is `mise hook-env`. Against
    the 10 ms perception threshold `command_lag` now sits 14% over instead of
    ~2×.
    The script clones zsh-bench pinned to a SHA into `~/.cache` on first use;
    it is deliberately absent from the Brewfile (no formula, no upstream tag)
    and from `./install` (which pulls, and would move the baseline). On Linux
    zsh-bench runs its payload through `$SHELL`, not the shell in `/etc/passwd`:
    with a bash `$SHELL` it does not fail, it **hangs forever with no output**
    — hence the forced `SHELL` and the `timeout` wrapper in the script. A server
    also needs its own ceilings, a VPS is nothing like the Mac:
    `MAX_FIRST_PROMPT_LAG=400 MAX_COMMAND_LAG=60 scripts/bench-shell.sh`.
  - `scripts/trace-shell.sh` — where the time goes, per sourced file (`-x` for
    per line). A ranking, not absolute costs: the DEBUG trap that keeps the
    timestamp alive through pure's `PROMPT4` costs ~20%, charged per command
    executed rather than per millisecond, so files running many cheap commands
    are over-charged (spread ~1.1-2×).
  Any costly addition must be lazy-loaded or cached: `fzf` and `mise` both
  generate their init script into `~/.cache`, regenerated only when the binary
  is newer, because each of them forks otherwise. `zsh-patina activate` is the
  documented **exception** — it forks ~4 ms and must still run every time,
  because that call is what starts the daemon and the script it prints carries
  the version the daemon checks per request. Cached, the daemon never starts
  and the emitted script returns silently on the missing socket: highlighting
  dies with nothing on stderr. `zsh-patina check` diagnoses it, from an
  activated shell — it also warns that `~/.zshrc` lacks the string
  `zsh-patina activate`, which is a false positive here, the call lives in
  `zsh/plugins.zsh`.
  `mise activate` still forks `mise hook-env` from `precmd` on every prompt
  (~11 ms), which is now the whole of `command_lag` — the autosuggestions
  rebind that used to be the other half is gone — and is invisible to the
  `exit` check.

## Pre-commit checks

A hook enforces part of this. `others/git-templates/hooks/pre-commit` refuses a
commit whose **added** lines carry a private key, a password assignment, a
VS Code Remote-SSH host list or a provider token; `./install` points
`core.hooksPath` at it, since `init.templateDir` only seeds new repositories.
`others/my.cnf` is an accepted path. Bypass with `git commit --no-verify`.

```sh
zsh -n <file.zsh>             # zsh syntax
bash -n <file.sh>             # bash syntax (shell/aliases*.sh must pass both)
shellcheck install scripts/*.sh macos-defaults.sh others/git-templates/hooks/pre-commit
./install                     # must remain idempotent (zero prompts, re-runnable)
time zsh -i -c exit           # portable smoke test < 130 ms (blind after zshrc)
scripts/bench-shell.sh        # zsh-bench in a pty: the latencies the line above misses
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
