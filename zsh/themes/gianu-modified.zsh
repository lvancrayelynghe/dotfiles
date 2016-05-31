# Load colors vars http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#index-colors
autoload -U colors && colors

# Setup the prompt with pretty colors, allow parameter expansion, command substitution and arithmetic expansion in prompts
setopt prompt_subst

# Context: user@hostname (who am I and where am I)
user_and_host() {
  local user=`whoami`
  if [[ "$user" == "benoth" || "$user" == "luc" ]]; then
    [[ -z "$SSH_CONNECTION" ]] && print -n "\ue00d" || print -n "SSH"
  elif [[ "$user" == "vagrant" ]]; then
    print -n "$user"
  elif [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    print -n "$user@%m"
  fi
}

# Speeded up native git_prompt_info()
git_prompt_info() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$ZSH_THEME_GIT_PROMPT_SUFFIX"
}

PROMPT='[$(user_and_host) %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)%{$reset_color%}]$ '

ZSH_THEME_GIT_PROMPT_PREFIX="(%{$fg_bold[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%} %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$reset_color%}"
