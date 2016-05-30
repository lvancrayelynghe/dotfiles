# commands to ignore
cmdignore=(man su gl gll tmux htop top vim v desk dg ssh mysql mysqldump webpack-dev-server)

# set gt 0 to enable GNU units for time results
gnuunits=0

# get the current active window id
function active-window-id {
    echo `xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}'`
}

# end and compare timer, notify-send if needed
function notifyosd-precmd() {
	retval=$?
    if [[ ${cmdignore[(r)$cmd_basename]} == $cmd_basename ]]; then
        return
    else
        if [ ! -z "$cmd" ]; then
            cmd_end=`date +%s`
            ((cmd_secs=$cmd_end - $cmd_start))
        fi
        if [ $retval -gt 0 ]; then
			cmdstat="with warning"
			sndstat="/usr/share/sounds/ubuntu/notifications/Rhodes.ogg"
			urgency="critical"
		else
            cmdstat="successfully"
			sndstat="/usr/share/sounds/ubuntu/notifications/Positive.ogg"
			urgency="normal"
        fi
        if [ ! -z "$cmd" -a $cmd_secs -gt 10 -a "$window_id_before" != "$(active-window-id)" ]; then
			if [ $gnuunits -gt 0 ]; then
				cmd_time=$(units "$cmd_secs seconds" "centuries;years;months;weeks;days;hours;minutes;seconds" | sed -e 's/\ +/\,/g' -e s'/\t//')
			else
				cmd_time="$cmd_secs seconds"
			fi
            if [ ! -z $SSH_TTY ] ; then
                notify-send -i utilities-terminal -u $urgency "$cmd_basename on `hostname` completed $cmdstat" "\"$cmd\" took $cmd_time"
				play -q $sndstat &>/dev/null
            else
                notify-send -i utilities-terminal -u $urgency "$cmd_basename completed $cmdstat" "\"$cmd\" took $cmd_time"
				play -q $sndstat &>/dev/null
            fi
        fi
        unset cmd
    fi
}

# make sure this plays nicely with any existing precmd
precmd_functions+=( notifyosd-precmd )

# get command name and start the timer
function notifyosd-preexec() {
    window_id_before=$(active-window-id)
    cmd=$1
    cmd_basename=${${cmd:s/sudo //}[(ws: :)1]}
    cmd_start=`date +%s`
}

# make sure this plays nicely with any existing preexec
preexec_functions+=( notifyosd-preexec )
