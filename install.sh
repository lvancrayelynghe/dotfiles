#!/bin/bash

# Clone & config repository
cd
git clone --recursive git://github.com/Benoth/dotfiles.git
cd dotfiles
chmod u+x *.sh
git config --local user.email "benoth83@gmail.com"
git config --local user.name "Benoth"

# Create the symlinks
./symlink-dotfiles.sh
