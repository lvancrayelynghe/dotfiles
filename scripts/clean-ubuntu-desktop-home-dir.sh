#!/usr/bin/env bash

cd ~
rm -rf Documents Modèles Images Vidéos Musique Public Téléchargements examples.desktop
xdg-user-dirs-update

# Reassign path :
# xdg-user-dirs-update --set NAME ABSOLUTE_PATH
#
# Available values for NAME
#   DESKTOP
#   DOWNLOAD
#   TEMPLATES
#   PUBLICSHARE
#   DOCUMENTS
#   MUSIC
#   PICTURES
#   VIDEOS
