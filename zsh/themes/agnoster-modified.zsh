# Reworked agnoster's Theme - https://gist.github.com/3712874
# Based on https://gist.github.com/rjorgenson/83094662ace4d3b82b95
#
# In order for this theme to render correctly, you will need a
# Powerline-patched font https://github.com/powerline/fonts
#
# Recommanded Solarized theme https://github.com/altercation/solarized/

########################################
### SEGMENTS DRAWING ###################
### A few utility functions to make it easy and re-usable to draw segmented prompts

# Begin a left segment. Takes three arguments, background and foreground and content
create_left_segment() {
  TRIMED="$(echo -e "${3}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" # trim
  if [[ -n $TRIMED ]]; then
    local bg fg
    [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
    [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
    if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
      print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
    else
      print -n "%{$bg%}%{$fg%}"
    fi
    CURRENT_BG=$1
    print -n $3
  fi
}

# Begin a right segment. Takes three arguments, background and foreground and content
create_right_segment() {
  TRIMED="$(echo -e "${3}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" # trim
  if [[ -n $TRIMED ]]; then
    local bg fg
    [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
    [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
    if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
      echo -n "%{%K{$CURRENT_BG}%F{$1}%}$RSEGMENT_SEPARATOR%{$bg%}%{$fg%}"
    else
      echo -n "%F{$1}%{%K{default}%}$RSEGMENT_SEPARATOR%{$bg%}%{$fg%}"
    fi
    CURRENT_BG=$1
    echo -n $3
  fi
}

# End the prompt, closing any open segments
end_left_prompt() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}


########################################
### PROMPT COMPONENTS ##################
### Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
component_user_and_host() {
  local user=`whoami`
  if [[ "$user" == "benoth" || "$user" == "luc" ]]; then
    [[ -z "$SSH_CONNECTION" ]] && print -n "$SELF" || print -n "SSH"
  elif [[ "$user" == "vagrant" ]]; then
    print -n "$user"
  elif [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    print -n "$user@%m"
  fi
}

# Desk name
component_desk() {
  [[ -n $DESK_NAME ]] && print -n "$DESK_NAME"
}

# Last command error return code
component_return_code() {
  [[ $RETVAL -ne 0 && $RETVAL -ne 20 ]] && print -n "$CROSS"
}

# Is user root
component_root() {
  [[ $UID -eq 0 ]] && print -n "$LIGHTNING"
}

# Background jobs
component_jobs() {
  [[ $(jobs -l | wc -l) -gt 0 ]] && print -n "$CLOCK"
}

# Git: branch/detached head, dirty status
component_git() {
  # Do not check git status if in a mount point
  if [ `stat -fc%t:%T .` != `stat -fc%t:%T "$HOME"` ]; then
    return 0
  fi

  if [[ -n $ZSH_VCS_INFO ]]; then
    vcs_info
  fi

  local ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      ref="${ref} $PLUSMINUS"
    else
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    print -Pn "$ref"
  fi
}

# Current working directory
component_pwd() {
  local current_path='%~'
  # current_path=$(pwd | sed -e "s,^$HOME,~," | sed -r "s/([^/]{2})[^/]+([^/]{2})\//\1…\2\//g")
  # current_path=$(pwd | sed -e "s,^$HOME,~," | sed -r "s/([^/]{2})[^/]+\//\1…\//g")
  # current_path="%$((3))(c:…/:)%2c"

  DIR=`pwd | sed -e "s!$HOME!~!"`
  if [ ${#DIR} -gt 35 ]; then
    CURDIR=${DIR:0:15}...${DIR:${#DIR}-17}
  else
    CURDIR=$DIR
  fi

  print -n "$CURDIR"
}


########################################
### PROMPTS BUILDING ###################

# Left prompt
prompt_left_part() {
  create_left_segment $PRIMARY_FG default      " $(component_user_and_host) "
  create_left_segment $COLOR_BLUE $PRIMARY_FG  " $(component_pwd) "
  create_left_segment $COLOR_GREEN $PRIMARY_FG " $(component_git) "
  end_left_prompt
}

# Right prompt
prompt_right_part() {
  echo -n " "
  create_right_segment $COLOR_WHITE $COLOR_BLACK " $(component_desk) "
  create_right_segment $COLOR_YELLOW $PRIMARY_FG " $(component_jobs) "
}

# Hook
prompt_precmd_hook() {
  PROMPT='%{%f%b%k%}$(prompt_left_part) '
  TRIMED="$(echo -e "$(prompt_right_part)" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" # trim
  if [[ -n $TRIMED ]]; then
    RPROMPT=$TRIMED
  fi
}

# Setup
prompt_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  autoload -U colors && colors  # Load colors vars http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#index-colors
  setopt prompt_subst           # Setup the prompt with pretty colors, allow parameter expansion, command substitution and arithmetic expansion in prompts

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_precmd_hook

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_setup "$@"

# Dump with: for code in {000..255}; do print -P -- "$code: %K{$code}          %k %F{$code}Foreground%f"; done
if [[ $TERM == *"256"* ]]; then
  COLOR_BLACK=233
  COLOR_WHITE=255
  COLOR_RED=9
  COLOR_GREEN=10
  COLOR_YELLOW=11
  COLOR_BLUE=12
  COLOR_MAGENTA=14
  COLOR_CYAN=14
else
  COLOR_BLACK=black
  COLOR_WHITE=white
  COLOR_BLUE=blue
  COLOR_CYAN=cyan
  COLOR_GREEN=green
  COLOR_YELLOW=yellow
  COLOR_MAGENTA=magenta
  COLOR_RED=red
fi

# Base colors
CURRENT_BG='NONE'
PRIMARY_FG=$COLOR_BLACK

# Characters
SEGMENT_SEPARATOR="\ue0b0"
RSEGMENT_SEPARATOR="\ue0b2"
SEGMENT_SMALL="\u25b6"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2297"
LIGHTNING="\u221a"
CLOCK="\u25d4"
SELF="\u25c8"
