#!/bin/sh

function getFocusedNodeId() {
    echo "$(bspc query -N -n)"
}

function getMonitorNodesIds() {
    monitorName="$1"
    echo "$(bspc query -N -d $monitorName:focused -n .window)"
}

function getNodePrimaryClass() {
    window="$1"
    echo "$(xprop -id $window WM_CLASS | grep -oe '".*"$' | sed 's/, "URxvt"//g' | rev | cut -d, -f1 | rev | sed -e 's/org.gnome.//gI' -e 's/"//g' -e 's/[_-]/ /g' | xargs | tr '[:upper:]' '[:lower:]')"
}

function getNodeTitle() {
    window="$1"
    echo "$(xtitle $window)"
}
