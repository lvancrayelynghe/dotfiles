#!/bin/bash

mkdir -p $HOME/.config/xfce4
rsync -av --progress -h --exclude-from=$HOME/.cvsignore \
  config/xfce4/* \
  $HOME/.config/xfce4

mkdir -p $HOME/.config/Thunar
rsync -av --progress -h --exclude-from=$HOME/.cvsignore \
  config/Thunar/*  \
  $HOME/.config/Thunar

mkdir -p $HOME/.gconf/apps/dockbarx
rsync -av --progress -h --exclude-from=$HOME/.cvsignore \
  gconf/apps/dockbarx/%gconf.xml \
  $HOME/.gconf/apps/dockbarx/%gconf.xml

sed -i -E "s|/home/[[:alnum:]]+/|$HOME/|g" $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
