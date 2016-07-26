#!/bin/bash

mkdir -p config/xfce4
rsync -av --progress -h --exclude-from=$HOME/.cvsignore \
  --exclude=desktop \
  --exclude=*.desktop \
  --exclude=*.rc.* \
  --exclude=xfce4-notes-plugin-*.rc \
  --exclude=displays.xml \
  --exclude=parole.xml \
  --exclude=ristretto.xml \
  --exclude=xfce4-settings-editor.xml \
  --exclude=xfce4-screenshooter \
  $HOME/.config/xfce4/* \
  config/xfce4

mkdir -p config/Thunar
rsync -av --progress -h --exclude-from=$HOME/.cvsignore \
  $HOME/.config/Thunar/* \
  config/Thunar

mkdir -p gconf/apps/dockbarx
rsync -av --progress -h --exclude-from=$HOME/.cvsignore \
  $HOME/.gconf/apps/dockbarx/%gconf.xml \
  gconf/apps/dockbarx/%gconf.xml

sed -i -E "s|/home/[[:alnum:]]+/|/home/benoth/|g" config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
