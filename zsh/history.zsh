#!/usr/bin/env zsh

## Command history configuration
if [ -z "$HISTFILE" ]; then
    HISTFILE=$HOME/.cache/zsh-history
fi

HISTSIZE=10000
SAVEHIST=10000

# Show history
case $HIST_STAMPS in
  "mm/dd/yyyy") alias history='fc -fl 1' ;;
  "dd.mm.yyyy") alias history='fc -El 1' ;;
  "yyyy-mm-dd") alias history='fc -il 1' ;;
  *) alias history='fc -l 1' ;;
esac

setopt append_history         # append to history file, rather than replace it on new session
setopt extended_history       # save each command’s beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file.
setopt hist_expire_dups_first # if the internal history needs to be trimmed to add the current command line, setting this option will cause the oldest history event that has a duplicate to be lost before losing a unique event from the list.
setopt hist_ignore_dups       # ignore duplication command history list
setopt hist_ignore_space      # remove command lines from the history list when the first character on the line is a space,
setopt hist_verify            # whenever the user enters a line with history expansion, don’t execute the line directly; instead, perform history expansion and reload the line into the editing buffer.
setopt inc_append_history     # new history lines are added to the $HISTFILE incrementally as soon as they are entered
setopt share_history          # share command history data
