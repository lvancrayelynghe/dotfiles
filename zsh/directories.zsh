#!/usr/bin/env zsh

setopt auto_pushd        # Make cd push the old directory onto the directory stack.
setopt pushd_ignore_dups # don't push multiple copies of the same directory onto the directory stack
setopt pushdminus        # Reverts the +/- operators (for cd +<TAB> and cd -<TAB>)
setopt auto_cd           # If you type foo, and it isn't a command, and it is a directory in your cdpath, go there
setopt cdable_vars       # cd to named dirs without ~ at beginning

# hash -d s="$HOME/shared"
# cd ~d => will show aliased in prompt => ~d $
