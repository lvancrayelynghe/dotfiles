# Keynames
ampersand
eacute
quotedbl
apostrophe
parenleft
minus
egrave
egrave
underscore
ccedilla
agrave

# Xdotool
apt-get install xdotool
xdotool key --clearmodifiers super+ampersand

# Xte
apt-get install xautomation
xte 'keydown Super_L' 'key 1' 'keyup Super_L'

# wmctrl
wmctrl -xa Chromium || chromium-browser
wmctrl -xa Thunar || thunar
