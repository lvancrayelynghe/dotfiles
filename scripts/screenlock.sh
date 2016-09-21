#!/usr/bin/env bash
# requires imagemagick

icon="$HOME/.config/xlock/icon.png"
tmpbg='/tmp/screenlock.png'

scrot "$tmpbg"
convert "$tmpbg" -scale 10% -scale 1000% "$tmpbg"
[[ -e $icon ]] && convert "$tmpbg" "$icon" -gravity center -composite -matte "$tmpbg"
i3lock -u -i "$tmpbg"
