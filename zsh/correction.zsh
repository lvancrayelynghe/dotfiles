#!/usr/bin/env zsh

if [[ "$ENABLE_CORRECTION" == "true" ]]; then
  alias ebuild='nocorrect ebuild'
  alias gist='nocorrect gist'
  alias gcc='nocorrect gcc'
  alias heroku='nocorrect heroku'
  alias hpodder='nocorrect hpodder'
  alias man='nocorrect man'
  alias mkdir='nocorrect mkdir'
  alias mv='nocorrect mv'
  alias rm='nocorrect rm'
  alias ln='nocorrect ln'
  alias cp='nocorrect cp'
  alias mysql='nocorrect mysql'
  alias sudo='nocorrect sudo'

  setopt correct_all # try to correct the spelling of all arguments in a line.
fi
