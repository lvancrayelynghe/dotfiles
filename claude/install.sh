#!/usr/bin/env bash
#
# Registers the Claude Code status line in ~/.claude/settings.json.
# Idempotent and non-destructive: it only sets the `statusLine` key and leaves
# everything else (permissions, model, marketplaces…) untouched.
#
# The status line SCRIPT itself is symlinked by mise ([dotfiles] in
# mise/config.toml):
# claude/statusline-command.sh -> ~/.claude/statusline-command.sh), so it stays
# in sync with the repo. settings.json is intentionally NOT symlinked because
# Claude Code rewrites it (permission approvals, atomic saves).
#
# Called automatically by ./install, but safe to run
# by hand at any time:  bash ~/.dotfiles/public/claude/install.sh
set -u

CLAUDE_DIR="${HOME}/.claude"
SETTINGS="${CLAUDE_DIR}/settings.json"
CMD="bash ~/.claude/statusline-command.sh"

mkdir -p "$CLAUDE_DIR"

# No settings file yet (fresh machine) → create a minimal one, no jq needed.
if [ ! -f "$SETTINGS" ]; then
    cat > "$SETTINGS" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "${CMD}"
  }
}
EOF
    echo "  [claude] created ${SETTINGS} with statusLine"
    exit 0
fi

# Existing settings → merge the statusLine key in place (needs jq).
if ! command -v jq >/dev/null 2>&1; then
    echo "  [claude] jq not found — add this to ${SETTINGS} manually:"
    echo "           \"statusLine\": { \"type\": \"command\", \"command\": \"${CMD}\" }"
    exit 0
fi

tmp="$(mktemp "${SETTINGS}.XXXXXX")"
if jq --arg cmd "$CMD" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"; then
    mv "$tmp" "$SETTINGS"
    echo "  [claude] statusLine registered in ${SETTINGS}"
else
    echo "  [claude] FAILED to update ${SETTINGS} (left untouched)"
    rm -f "$tmp"
fi
