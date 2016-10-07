#!/bin/sh

wid=$1
class=$(echo ${2} | xargs)
instance=$(echo ${3} | xargs)
# title=$(xtitle "$wid")

# Debug
# echo "$wid $class $instance" > /tmp/bspc-external-rules

eval $(xwininfo -id $wid | \
    sed -n -e "s/^ \+Absolute upper-left X: \+\([0-9]\+\).*/x=\1/p" \
       -e "s/^ \+Absolute upper-left Y: \+\([0-9]\+\).*/y=\1/p" \
       -e "s/^ \+Width: \+\([0-9]\+\).*/w=\1/p" \
       -e "s/^ \+Height: \+\([0-9]\+\).*/h=\1/p" )

if [ "$instance" = "popup-calendar" ] ; then
    echo "state=floating"
    echo "focus=on"
    echo "border=off"

    xdotool windowmove $wid $((1920 - $w)) $(($PANEL_HEIGHT+5))
    xdotool windowactivate $wid
    exit 0
fi

# Pseudo automatic mode
fawid=$(bspc query -N -n focused.automatic)
if [ -n "$fawid" ] ; then
    eval $(xwininfo -id $fawid | \
        sed -n \
           -e "s/^ \+Width: \+\([0-9]\+\).*/faw=\1/p" \
           -e "s/^ \+Height: \+\([0-9]\+\).*/fah=\1/p" )
    if [ $faw -gt $fah ] ; then
        echo "split_dir=east"
    else
        echo "split_dir=south"
    fi
fi
