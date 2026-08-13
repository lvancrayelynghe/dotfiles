# Claude Code

Custom [Claude Code](https://claude.com/claude-code) status line.

`statusline-command.sh` renders a dense, color-coded status bar from the JSON
payload Claude Code pipes to `statusLine` commands. It reads the native
`context_window` object (exact token usage + window size), both rate limits
(5h / 7d), session cost, lines added/removed, effort, thinking and fast-mode
flags. Tweak the `CFG_*` toggles at the top of the script to show/hide segments.

## How it gets installed

`./install` handles it in two steps:

1. **Symlink** — `claude/statusline-command.sh` → `~/.claude/statusline-command.sh`
   (declared in `.dotter/global.toml`). Claude Code never writes to this
   file, so the symlink stays valid and edits in the repo take effect immediately.
2. **Register** — `./install` runs `claude/install.sh`,
   which sets the `statusLine` key in `~/.claude/settings.json` (idempotent,
   non-destructive). `settings.json` is deliberately **not** symlinked: Claude
   Code rewrites it (permission approvals, atomic saves), which would break a
   symlink.

## Requirements

- `jq` — used by the status line at runtime and by `install.sh` to merge
  settings. Installed via the `Brewfile` on macOS (`brew bundle`). On Linux
  install it with your package manager (e.g. `apt install jq`).
