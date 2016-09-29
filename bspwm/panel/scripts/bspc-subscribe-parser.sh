#!/bin/sh

function countMonitors() {
    state="$1"

    count=0
    IFS=':'
    set -- ${state#?}
    first_time=true
    while [ $# -gt 0 ]; do
        if [[ "$1" == [mM]* ]]; then
            count=$(echo "${count}+1" | bc)
        fi
        shift
    done

    echo "${count}"
    exit 0
}

function getMonitorState() {
    position="$1"
    state="$2"

    declare -a monitors
    count=0
    IFS=':'
    set -- ${state#?}
    first_time=true
    while [ $# -gt 0 ]; do
        if [[ "$1" == [mM]* ]]; then
            if [[ "$first_time" != true ]]; then
                monitors[count++]="$mon"
            fi
            mon="${1}"
            first_time=false
        else
            mon="${mon}:${1}"
        fi
        shift
    done
    monitors[count++]="$mon"

    echo "${monitors[$position]}"
    exit 0
}

function getFocusedMonitor() {
    state="$1"

    declare -a monitors
    count=0
    IFS=':'
    set -- ${state#?}
    while [ $# -gt 0 ]; do
        if [[ "$1" == [M]* ]]; then
            echo "${1#?}"
            exit 0
        fi
        shift
    done
    exit 1
}

function getMonitorName() {
    state="$1"

    IFS=':'
    set -- ${state}
    while [ $# -gt 0 ]; do
        echo "${1#?}"
        exit 0
    done
    exit 1
}

function getDesktops() {
    state="$1"

    declare -a desktops
    count=0
    IFS=':'
    set -- ${state#?}
    first_time=true
    while [ $# -gt 0 ]; do
        if [[ "$1" == [fFoOuU]* ]]; then
            if [[ "$first_time" != true ]]; then
                desktops[count++]="${desk}"
            fi
            desk="${1#?}"
            first_time=false
        fi
        shift
    done
    desktops[count++]="${desk}"

    echo "${desktops[@]}"
    exit 0
}

function getActiveDesktop() {
    state="$1"

    IFS=':'
    set -- ${state#?}
    while [ $# -gt 0 ]; do
        if [[ "$1" == [FOU]* ]]; then
            echo "${1#?}"
            exit 0
        fi
        shift
    done
    exit 1
}

function getDesktopLayout() {
    desktop="$1"
    state="$2"

    IFS=':'
    set -- ${state#?}
    while [ $# -gt 0 ]; do
        if [[ "$1" == [L]* ]]; then
            case "${1#?}" in
                T)
                    echo "tiled" ;;
                M)
                    echo "monocle" ;;
            esac
            exit 0
        fi
        shift
    done
    exit 1
}

function getDesktopActiveWindowState() {
    desktop="$1"
    state="$2"

    IFS=':'
    set -- ${state#?}
    while [ $# -gt 0 ]; do
        if [[ "$1" == [T]* ]]; then
            case "${1#?}" in
                T)
                    echo "tiled" ;;
                P)
                    echo "pseudo_tiled" ;;
                F)
                    echo "floating" ;;
                =)
                    echo "fullscreen" ;;
                @)
                    echo "-" ;;
            esac
            exit 0
        fi
        shift
    done
    exit 1
}

function getDesktopActiveWindowFlags() {
    desktop="$1"
    state="$2"

    declare -a flags
    IFS=':'
    set -- ${state#?}
    while [ $# -gt 0 ]; do
        if [[ "$1" == [G]* ]]; then
            case "${1#?}" in
                S)
                    flags+=("sticky") ;;
                P)
                    flags+=("private") ;;
                L)
                    flags+=("locked") ;;
                H)
                    flags+=("hidden") ;;
                U)
                    flags+=("urgent") ;;
            esac
        fi
        shift
    done
    echo "${flags[@]}"
    exit 0
}
