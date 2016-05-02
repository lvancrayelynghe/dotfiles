#!/usr/bin/env bash

WINDOWID=$(wmctrl -l | grep -e " – Chromium$" | awk -F ' ' '{print $1}')
wmctrl -i -a $WINDOWID
xdotool key ctrl+t
