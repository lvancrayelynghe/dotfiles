#!/usr/bin/env zsh

#compdef artisan
# ------------------------------------------------------------------------------
# Copyright (c) 2011 Github zsh-users - http://github.com/zsh-users
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# * Neither the name of the zsh-users nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL ZSH-USERS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ------------------------------------------------------------------------------
# Description
# -----------
#
#  Completion script for artisan (http://laravel.com/docs/artisan).
#
# ------------------------------------------------------------------------------
# Authors
# -------
#
#  * loranger (https://github.com/loranger)
#  * Yohan Tambè (https://github.com/Cronos87)
#
# ------------------------------------------------------------------------------


_artisan_get_command_list () {
    IFS=" "
    php artisan --no-ansi | \
        sed "1,/Available commands/d" | \
        awk '/ [a-z]+/ { print $1 }' | \
        sed -E 's/^[ ]+//g' | \
        sed -E 's/[:]+/\\:/g' | \
        sed -E 's/[ ]{2,}/\:/g'
}

_artisan () {
    if [ -f artisan ]; then
        local -a commands
        IFS=$'\n'
        commands=($(_artisan_get_command_list))
        _describe 'commands' commands
    fi
}

# `compdef _artisan php artisan` binds _artisan to *both* names -- compdef has
# no notion of a two-word command -- so every `php <TAB>` landed in _artisan.
# Outside a Laravel root it adds nothing yet still returns 0, so the completion
# system considers the word handled and never falls back: `php path/to/scr<TAB>`
# completed nothing at all. Dispatch by hand instead.
_php_or_artisan() {
    if (( CURRENT > 2 )) && [[ $words[2] == artisan ]]; then
        # let _artisan see itself as words[1]; both are restored on return
        local -a words=( "${(@)words[2,-1]}" )
        local CURRENT=$(( CURRENT - 1 ))
        _artisan "$@"
    elif (( $+functions[_php] )); then   # autoload stub declared by compinit
        _php "$@"
    else
        _default "$@"
    fi
}

compdef _php_or_artisan php
compdef _artisan artisan
compdef _artisan art
