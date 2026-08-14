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
  (`recurse = false`) so that Hammerspoon's pathwatcher resolves the repo
  directory: **any `.lua` saved here reloads the live config at once**, and a
  syntax error takes that config down until the next save. Hence `luac -p`
  right after writing, and drafting anything substantial elsewhere first.
  `init.lua` requires `lib/switcher`, `caffeinate`, `keymappings`, `layouts`.
  - `lib/switcher.lua` is vendored (PorcoSpoon / dmg) and keeps its **3-space
    indentation**; the other files are on 4 like the rest of the repo.
  - A watcher or an eventtap must stay reachable from a live value or it is
    garbage-collected and **silently stops** — `hs.eventtap`'s `__gc` disables
    the tap outright. Hence `configWatcher` and `mediaKeyTap` global, and
    `obj.wakeWatcher` / `obj.spacesWatcher` on the switcher's module table. A
    module-level `local` is *not* enough: nothing references a chunk's locals
    once it has run, unless a live callback captures them.
  - Applications are addressed by **bundle id**, never by name: `apps.lua` holds
    the table and the two other files read it. Names fail three different ways —
    `get(name)` and `find(name)` match on **substrings** (`"Code"` also finds
    Xcode) then fall back to searching **every window title**, so they readily
    return the browser holding a tab named after the app; `find(name, true)` is
    exact but against the **localised** name (`Musique`, `Calendrier`); and
    `open(name)` wants the **bundle's** name, which is often not the app's, so
    `"Code"` launches nothing — the bundle is `Visual Studio Code.app`.
    `applicationsForBundleID()` and `open(bundleID)` have none of it. To find an
    id: `bundleid <name|path>`, or `bundleid -l` when the name is the problem
    (`shell/aliases-macos.sh`).
  - `hs.layout.apply` is the one exception: it takes a name or an
    `hs.application` object, never a bundle id (`layout.lua:147-155`), hence
    `resolve()` in `layouts.lua`. It drops what is not running rather than
    passing nil, which would only print `No windows matched` per entry.
  - `hs.window.filter` only ever sees the **current Space** (`app:allWindows()`
    can do no better), and it loses a window for good whenever the
    accessibility API is briefly incoherent — a wake, a Space transition. It
    says so with `wfilter: <app> (<window id>) is STILL not registered`, and
    from then on reports no event at all for that window.
    `hs.window.filter.switchedToSpace(-1)` is the lever that forces a
    re-enumeration: `-1` is the one Space number never memoised in its
    `spacesDone`, so unlike a real number it refreshes on every call.
    `lib/switcher.lua` therefore rebuilds its own list from
    `hs.window.orderedWindows()` instead of trusting the filter's bookkeeping,
    and keeps its rules by checking `allowedWindowRoles` itself.
    **`isWindowAllowed()` is unusable for that**: on a subscribed filter it
    short-circuits to "is this window in my tracked set?" — the very bookkeeping
    being bypassed — and gets even that wrong, since `window_filter.lua:280`
    indexes a `Window`-keyed table with a window id and so returns `false` for
    every window.
  - `hs.window:focus()` is `becomeMain()` plus `_bringtofront()` and **reveals
    nothing**: a minimized window stays minimized — its application merely comes
    forward and shows another of its windows, so the switch looks like it did
    nothing — and a hidden application stays hidden. `lib/switcher.lua` raises a
    window through `reveal()`, which undoes both first. The accessibility calls
    are animated, so the state only settles a fraction of a second later.
  - `hs.urlevent.bind()` is how a terminal reaches the config: the scheme is
    claimed by the app itself, so this needs nothing installed and turns nothing
    on, unlike `hs.ipc` or `hs.allowAppleScript`. Two events are bound, and
    **both names are a contract** with `shell/aliases-macos.sh`:
    `caffeinate?action=toggle|on|off`, wrapped by `caffeine()`, which reads the
    resulting state back from `pmset` — going through Hammerspoon rather than
    running `caffeinate -d` in the shell is what keeps a single holder of the
    assertion, and a menubar icon that cannot lie; and `screens`, wrapped by
    `screenid()`, answered through `~/.cache/hammerspoon-screens.txt`.
  - `layouts.lua` names **no screen**: its rows carry a role (`laptop`,
    `horizontal`, `vertical`) that `resolve()` swaps for an `hs.screen` object,
    and the setup — `single`, `dual`, `triple` — follows from which roles are
    present. Names were the trap, twice over: `hs.screen:name()` is
    `NSScreen.localizedName` (`libscreen.m:78`), localised for **the calling
    application**, so Hammerspoon (English only) says `Built-in Retina Display`
    where a French `osascript` is told `Écran Retina intégré` — neither `LANG`
    nor `AppleLanguages` changes that; and `(1)`/`(2)` on two identical monitors
    is an ordering macOS assigns, and can swap between reconnections. Roles come
    from shape — taller than wide is the vertical one — except the Mac's own
    screen, which nothing identifies (`getInfo()` returns nil here,
    `CGDisplayIsBuiltin` is not exposed): hence the `Built-in` **prefix**, with
    the primary screen as fallback. `screenid` prints those roles, and such
    names would in any case be unusable with `hs.screen.find()`, which takes
    them as Lua patterns — `(1)` is a capture group. `hs.layout.apply` compares
    exactly, so it never was affected.
  - There is no `hs` CLI (`hs.ipc` is never required) and `hs.allowAppleScript`
    is off, so **the live state is only readable in the Hammerspoon console**:
    its output goes to no file, and not to the unified log either. A module is
    therefore tested by driving it under plain `lua` against a **stub `hs`
    table**, `hammerspoon/tests/` holding one suite per module. `test-switcher`
    also counts the accessibility sweep and the icon loading, so a keystroke
    paying for either twice fails the run; `test-layouts` records what
    `hs.layout.apply` is *asked* for instead of performing it, and drives the
    module the way a user does — through the function captured from
    `menu:setMenu()` — since layouts.lua exports nothing at all. Nothing runs
    them automatically; they are in the checks below. Add a case when touching
    either module: three of the bugs these caught were invisible in review.
  - To read the live state **from a terminal** rather than that console, use the
    reload as a probe: drop a temporary module in `hammerspoon/`, `require` it
    from `init.lua`, and have it write what it finds — or the result of an
    experiment — to a file. Saving either file triggers the reload that runs it,
    so no setting has to be turned on and nothing is left behind once both are
    reverted. That is how `focus()` was caught leaving a window minimized.
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
