#!/bin/bash

# Clone & config repository
cd
git clone --recursive https://github.com/Benoth/dotfiles.git
cd dotfiles
chmod u+x *.sh
git config --local user.email "benoth83@gmail.com"
git config --local user.name "Benoth"

# Create the symlinks
./bootstrap.sh

echo "All done. Re-run your session to finish the installation :)"
