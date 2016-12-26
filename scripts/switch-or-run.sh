#!/bin/bash
#
# Switch/focus between existing windows or run it if it does not exists
#
# Usage: switch-or-run AppName AppCommand
# Exemple: switch-or-run Chromium chromium-browser
# Exemple: switch-or-run "([A-Za-z0-9]*)\.Thunderbird" thunderbird

if [ "$#" -le 0 ]; then
    wmctrl -lx
    exit 0
fi

app_name=$1
workspace_number=`wmctrl -d | grep '\*' | cut -d' ' -f 1`

# Switch from the same workspace
# win_list=`wmctrl -lx | grep $app_name | grep " $workspace_number " | tac | awk '{print $1}'`

# Switch from all workspace
win_list=`wmctrl -lx | grep -Ei " $app_name " | tac | awk '{print $1}'`

active_win_id=`xprop -root | grep '^_NET_ACTIVE_W' | awk -F'# 0x' '{print $2}' | awk -F', ' '{print $1}'`
if [ "$active_win_id" == "0" ]; then
    active_win_id=""
fi

# get next window to focus on, removing id active
switch_to=`echo $win_list | sed s/.*$active_win_id// | awk '{print $1}'`

# if the current window is the last in the list ... take the first one
if [ "$switch_to" == "" ];then
    switch_to=`echo $win_list | awk '{print $1}'`
fi

if [[ -n "${switch_to}" ]]
    then
        (wmctrl -ia "$switch_to") &
    else
        if [[ -n "$2" ]]; then
            exec $2 &
        fi
fi

exit 0
