#!/bin/sh

urxvt -geometry 66x28 +sb -name 'popup-calendar' -e bash -c 'cal -B 3 -A 5 ; echo "Press any key to close..." ; read -n 1 ret' &
