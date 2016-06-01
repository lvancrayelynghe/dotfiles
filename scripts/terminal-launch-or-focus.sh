#!/usr/bin/env bash

WINDOWID=$(wmctrl -l | grep -e "Terminal$" | awk -F ' ' '{print $1}')
if [[ -n $WINDOWID ]]; then
    wmctrl -i -a $WINDOWID
else
    exec gnome-terminal
fi
