# CLAUDE.md — hammerspoon/

Adds to the repository's root `CLAUDE.md`, which still applies in full; this
file only holds what is specific to this directory, and loads when a file here
is read. Everything below was paid for in measurement — most of it is invisible
in review, and three of the bugs behind these notes shipped once already.

## The directory, and the reload

- `macos` package, mapped in `.dotter/global.toml` as a **single directory
  symlink** (`recurse = false`) so that Hammerspoon's pathwatcher resolves the
  repo directory: **any `.lua` saved here reloads the live config at once**, and
  a syntax error takes that config down until the next save. Hence `luac -p`
  right after writing, and drafting anything substantial elsewhere first.
- `init.lua` requires `lib/switcher`, `caffeinate`, `keymappings`, `layouts`.
- `lib/switcher.lua` is vendored (PorcoSpoon / dmg) and keeps its **3-space
  indentation**; the other files are on 4 like the rest of the repo.
- A watcher or an eventtap must stay reachable from a live value or it is
  garbage-collected and **silently stops** — `hs.eventtap`'s `__gc` disables the
  tap outright. Hence `configWatcher` and `mediaKeyTap` global, and
  `obj.wakeWatcher` / `obj.spacesWatcher` on the switcher's module table. A
  module-level `local` is *not* enough: nothing references a chunk's locals once
  it has run, unless a live callback captures them.

## Naming an application, naming a screen

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
- `hs.layout.apply` is the one exception: it takes a name or an `hs.application`
  object, never a bundle id (`layout.lua:147-155`), hence `resolve()` in
  `layouts.lua`. It drops what is not running rather than passing nil, which
  would only print `No windows matched` per entry.
- `layouts.lua` names **no screen**: its rows carry a role (`laptop`,
  `horizontal`, `vertical`) that `resolve()` swaps for an `hs.screen` object,
  and the setup — `single`, `dual`, `triple` — follows from which roles are
  present. Names were the trap, twice over: `hs.screen:name()` is
  `NSScreen.localizedName` (`libscreen.m:78`), localised for **the calling
  application**, so Hammerspoon (English only) says `Built-in Retina Display`
  where a French `osascript` is told `Écran Retina intégré` — neither `LANG` nor
  `AppleLanguages` changes that; and `(1)`/`(2)` on two identical monitors is an
  ordering macOS assigns, and can swap between reconnections. Roles come from
  shape — taller than wide is the vertical one — except the Mac's own screen,
  which nothing identifies (`getInfo()` returns nil here, `CGDisplayIsBuiltin`
  is not exposed): hence the `Built-in` **prefix**, with the primary screen as
  fallback. `screenid` prints those roles, and such names would in any case be
  unusable with `hs.screen.find()`, which takes them as Lua patterns — `(1)` is
  a capture group. `hs.layout.apply` compares exactly, so it never was affected.

## Windows: what these APIs do not do

- `resolve()` **names every window explicitly**, in slot 2 of the row, and that
  is load-bearing: left to find them itself, `hs.layout.apply` calls
  `app:allWindows()` (`layout.lua:200`), which only ever sees the Space active
  on each screen. A window on any other Space — where every fullscreen window
  lives — is invisible to it, so it prints `No windows matched, skipping` and
  the application does not move at all. Measured: `allWindows()` returned
  nothing for a fullscreen window, and still nothing 2.5 s after it had left
  fullscreen. That is what made a layout need applying **twice** — the first run
  only freed the windows, which brought them back onto an ordinary Space for the
  second. Given a window, `hs.layout.apply` enumerates nothing
  (`layout.lua:186-188`), and `mainWindow()` does reach across Spaces.
- Fullscreen transitions are **serialised by macOS**, and a request made while
  another is going through is silently dropped: measured, four fired in one tick
  left two windows behind, where the same four 0.9 s apart left only the one
  application that never accepts fullscreen at all. `toFullscreen()` is
  therefore a chain, not a loop — one request, a pause, a check, a couple of
  retries, then it moves on. It has to give up: **some applications have no
  fullscreen state to set** (measured on Harvest and Spotify), and asking
  forever is what makes macOS play its rejection sound. `isFullScreen()` answers
  the *request*, not the transition — it flips the instant the call is made — so
  the check belongs after the transition has had time to run, by which point a
  dropped request reads false again.
- `hs.window:focus()` is `becomeMain()` plus `_bringtofront()` and **reveals
  nothing**: a minimized window stays minimized — its application merely comes
  forward and shows another of its windows, so the switch looks like it did
  nothing — and a hidden application stays hidden. `lib/switcher.lua` raises a
  window through `reveal()`, which undoes both first. The accessibility calls
  are animated, so the state only settles a fraction of a second later.
- `hs.window.filter` only ever sees the **current Space** (`app:allWindows()`
  can do no better), and it loses a window for good whenever the accessibility
  API is briefly incoherent — a wake, a Space transition. It says so with
  `wfilter: <app> (<window id>) is STILL not registered`, and from then on
  reports no event at all for that window.
  `hs.window.filter.switchedToSpace(-1)` is the lever that forces a
  re-enumeration: `-1` is the one Space number never memoised in its
  `spacesDone`, so unlike a real number it refreshes on every call.
  `lib/switcher.lua` therefore rebuilds its own list from
  `hs.window.orderedWindows()` instead of trusting the filter's bookkeeping, and
  keeps its rules by checking `allowedWindowRoles` itself. **`isWindowAllowed()`
  is unusable for that**: on a subscribed filter it short-circuits to "is this
  window in my tracked set?" — the very bookkeeping being bypassed — and gets
  even that wrong, since `window_filter.lua:280` indexes a `Window`-keyed table
  with a window id and so returns `false` for every window.

## Reaching the config, and reading its state

- `hs.urlevent.bind()` is how a terminal reaches the config: the scheme is
  claimed by the app itself, so this needs nothing installed and turns nothing
  on, unlike `hs.ipc` or `hs.allowAppleScript`. Two events are bound, and **both
  names are a contract** with `shell/aliases-macos.sh`:
  `caffeinate?action=toggle|on|off`, wrapped by `caffeine()`, which reads the
  resulting state back from `pmset` — going through Hammerspoon rather than
  running `caffeinate -d` in the shell is what keeps a single holder of the
  assertion, and a menubar icon that cannot lie; and `screens`, wrapped by
  `screenid()`, answered through `~/.cache/hammerspoon-screens.txt`.
- There is no `hs` CLI (`hs.ipc` is never required) and `hs.allowAppleScript` is
  off, so **the live state is only readable in the Hammerspoon console**: its
  output goes to no file, and not to the unified log either. A module is
  therefore tested by driving it under plain `lua` against a **stub `hs`
  table**, `tests/` holding one suite per module. `test-switcher` also counts
  the accessibility sweep and the icon loading, so a keystroke paying for either
  twice fails the run; `test-layouts` records what `hs.layout.apply` is *asked*
  for instead of performing it, and drives the module the way a user does —
  through the function captured from `menu:setMenu()` — since `layouts.lua`
  exports nothing at all. Nothing runs them automatically; they are in the root
  `CLAUDE.md`'s pre-commit checks. Add a case when touching either module.
- To read the live state **from a terminal** rather than that console, use the
  reload as a probe: drop a temporary module here, `require` it from `init.lua`,
  and have it write what it finds — or the result of an experiment — to a file.
  Saving either file triggers the reload that runs it, so no setting has to be
  turned on and nothing is left behind once both are reverted. That is how
  `focus()` was caught leaving a window minimized.
