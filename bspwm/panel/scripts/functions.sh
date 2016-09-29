#!/bin/sh

function stringPad() {
    content="$(echo "$1" | cut -c 1-$maxLen)"
    maxLen=${2:-20}

    count=$(echo $content | wc -c)
    remain=$(( $maxLen - $count ))
    [ $(( $remain % 2 )) -ne 0 ] && remain=$(( $remain + 1 ))
    padding=""
    for i in $(seq $(( $remain / 2))); do
        padding="$padding "
    done

    echo "${padding}${content}${padding}";
}
