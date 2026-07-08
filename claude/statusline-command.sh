#!/bin/bash
# Claude Code status line.
# Reads the statusline JSON payload from stdin (schema of CC 2.1.x) and renders
# a single dense, color-coded line. All values come straight from the payload —
# no file-size guessing, no transcript parsing.
#
# Segments:  model · effort · 🧠 │ ctx <bar> % used/size │ 5h % ↻reset · 7d % │ dir ⎇branch │ +/- │ $cost ⏱dur
#
# Tweak the CFG_* toggles below to hide segments you don't want.

CFG_SHOW_MODEL=1
CFG_SHOW_THINKING=1
CFG_SHOW_CONTEXT=1
CFG_SHOW_LIMITS=1
CFG_SHOW_DIR=1
CFG_SHOW_DIFF=1
CFG_SHOW_COST=1
CFG_SHOW_DURATION=1
CFG_BAR_WIDTH=10
CFG_BRANCH_GLYPH="⎇"   # change to "" if your font can't render it

input=$(cat)

# ---- one jq call pulls every field we need (tab-separated) --------------------
IFS=$'\x1f' read -r \
    model_name effort fast_mode \
    ctx_pct ctx_used ctx_size \
    fh_pct fh_reset sd_pct sd_reset \
    cost cwd lines_added lines_removed thinking duration_ms \
  < <(printf '%s' "$input" | jq -r '
      [ (.model.display_name // "?"),
        (.effort.level // ""),
        (.fast_mode // false),
        (.context_window.used_percentage // -1),
        (.context_window.total_input_tokens
           // ((.context_window.current_usage.input_tokens // 0)
              + (.context_window.current_usage.cache_creation_input_tokens // 0)
              + (.context_window.current_usage.cache_read_input_tokens // 0))),
        (.context_window.context_window_size // 0),
        (.rate_limits.five_hour.used_percentage // -1),
        (.rate_limits.five_hour.resets_at // 0),
        (.rate_limits.seven_day.used_percentage // -1),
        (.rate_limits.seven_day.resets_at // 0),
        (.cost.total_cost_usd // 0),
        (.workspace.current_dir // ""),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0),
        (.thinking.enabled // false),
        (.cost.total_duration_ms // 0)
      ] | map(tostring) | join("\u001f")')

# ---- palette (256-color) ------------------------------------------------------
R=$'\033[0m'; DIM=$'\033[38;5;244m'; SEP=$'\033[38;5;240m'
C_MODEL=$'\033[38;5;146m'; C_DIR=$'\033[38;5;110m'; C_BRANCH=$'\033[38;5;108m'
C_GREEN=$'\033[38;5;71m'; C_YELLOW=$'\033[38;5;179m'; C_RED=$'\033[38;5;168m'

sep=" ${SEP}│${R} "

# color chosen by "fullness": higher = worse (green→yellow→red)
level_color() { local p=$1; (( p >= 80 )) && { printf '%s' "$C_RED"; return; }
                (( p >= 50 )) && { printf '%s' "$C_YELLOW"; return; }
                printf '%s' "$C_GREEN"; }

# 48752 -> 49k ; 1000000 -> 1M ; 1500000 -> 1.5M
humanize() { local n=$1
  if (( n >= 1000000 )); then
    if (( n % 1000000 == 0 )); then printf '%dM' $(( n / 1000000 ))
    else printf '%d.%dM' $(( n / 1000000 )) $(( (n % 1000000) / 100000 )); fi
  elif (( n >= 1000 )); then printf '%dk' $(( (n + 500) / 1000 ))
  else printf '%d' "$n"; fi; }

# 45000 -> 45s ; 320000 -> 5m ; 3920000 -> 1h05m
humanize_ms() { local s=$(( $1 / 1000 ))
  if (( s < 60 )); then printf '%ds' "$s"
  elif (( s < 3600 )); then printf '%dm' $(( s / 60 ))
  else printf '%dh%02dm' $(( s / 3600 )) $(( (s % 3600) / 60 )); fi; }

make_bar() { # $1=pct $2=fill-color
  local pct=$1 color=$2 w=$CFG_BAR_WIDTH filled i
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  filled=$(( (pct * w + 50) / 100 ))
  (( filled > w )) && filled=w
  printf '%s' "$color"
  for ((i=0; i<filled; i++)); do printf '█'; done
  printf '%s' "$DIM"
  for ((i=filled; i<w; i++)); do printf '░'; done
  printf '%s' "$R"; }

fmt_time() { # epoch -> HH:MM (local); empty on 0/invalid
  local t=$1; [[ -z "$t" || "$t" == "0" || "$t" == "null" ]] && return
  if [[ "$OSTYPE" == darwin* ]]; then date -r "$t" '+%H:%M' 2>/dev/null
  else date -d "@$t" '+%H:%M' 2>/dev/null; fi; }

segments=()

# ---- model (+ effort / fast-mode) --------------------------------------------
if (( CFG_SHOW_MODEL )); then
  seg="${C_MODEL}${model_name}${R}"
  [[ "$fast_mode" == "true" ]] && seg+="${C_YELLOW} ⚡${R}"
  [[ -n "$effort" && "$effort" != "null" ]] && seg+="${DIM} ${effort}${R}"
  (( CFG_SHOW_THINKING )) && [[ "$thinking" == "true" ]] && seg+="${DIM} 🧠${R}"
  segments+=("$seg")
fi

# ---- context window ----------------------------------------------------------
if (( CFG_SHOW_CONTEXT )); then
  if [[ "$ctx_pct" =~ ^-?[0-9]+$ ]] && (( ctx_pct >= 0 )); then
    col=$(level_color "$ctx_pct")
    seg="${DIM}ctx${R} $(make_bar "$ctx_pct" "$col") ${col}${ctx_pct}%${R}"
    if (( ctx_size > 0 )); then
      seg+=" ${DIM}$(humanize "$ctx_used")/$(humanize "$ctx_size")${R}"
    fi
    segments+=("$seg")
  else
    segments+=("${DIM}ctx n/a${R}")
  fi
fi

# ---- rate limits (5h + 7d) ---------------------------------------------------
if (( CFG_SHOW_LIMITS )); then
  parts=()
  if [[ "$fh_pct" =~ ^[0-9]+$ ]] && (( fh_pct >= 0 )); then
    col=$(level_color "$fh_pct"); t=$(fmt_time "$fh_reset")
    p="${DIM}5h${R} ${col}${fh_pct}%${R}"; [[ -n "$t" ]] && p+="${DIM} ↻${t}${R}"
    parts+=("$p")
  fi
  if [[ "$sd_pct" =~ ^[0-9]+$ ]] && (( sd_pct >= 0 )); then
    col=$(level_color "$sd_pct")
    parts+=("${DIM}7d${R} ${col}${sd_pct}%${R}")
  fi
  if (( ${#parts[@]} )); then
    joined=$(printf '%s' "${parts[0]}"); for ((k=1; k<${#parts[@]}; k++)); do joined+=" ${SEP}·${R} ${parts[k]}"; done
    segments+=("$joined")
  fi
fi

# ---- directory + git branch --------------------------------------------------
if (( CFG_SHOW_DIR )) && [[ -n "$cwd" ]]; then
  disp="${cwd/#$HOME/\~}"
  # collapse deep paths to …/parent/base
  if [[ $(tr -cd '/' <<<"$disp" | wc -c) -gt 2 ]]; then
    disp="…/$(basename "$(dirname "$disp")")/$(basename "$disp")"
  fi
  seg="${C_DIR}${disp}${R}"
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [[ -n "$branch" && "$branch" != "HEAD" ]] && seg+="${C_BRANCH} ${CFG_BRANCH_GLYPH} ${branch}${R}"
  segments+=("$seg")
fi

# ---- lines added / removed (session diff) ------------------------------------
if (( CFG_SHOW_DIFF )); then
  [[ "$lines_added"   =~ ^[0-9]+$ ]] || lines_added=0
  [[ "$lines_removed" =~ ^[0-9]+$ ]] || lines_removed=0
  segments+=("${C_GREEN}+${lines_added}${R}${DIM}/${R}${C_RED}-${lines_removed}${R}")
fi

# ---- cost --------------------------------------------------------------------
if (( CFG_SHOW_COST )); then
  cost_fmt=$(printf '%.2f' "$cost" 2>/dev/null || echo "0.00")
  seg="${DIM}\$${cost_fmt}${R}"
  if (( CFG_SHOW_DURATION )) && [[ "$duration_ms" =~ ^[0-9]+$ ]] && (( duration_ms > 0 )); then
    seg+="${DIM} ⏱ $(humanize_ms "$duration_ms")${R}"
  fi
  segments+=("$seg")
fi

# ---- render ------------------------------------------------------------------
out=""
for i in "${!segments[@]}"; do
  (( i > 0 )) && out+="$sep"
  out+="${segments[i]}"
done
printf '%s' "$out"
