#!/bin/sh
#
# usage: gif-rec [duration]

if [ -z $1 ]; then
    D=15
else
    D=$1
fi

eval $(slop)

byzanz-record -x ${X} -y ${Y} -w ${W} -h ${H} -d ${D} -v ~/record-$(date +%F-%T).gif
notify-send "Done !"
