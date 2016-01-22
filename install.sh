#!/bin/bash

# Clone & config the public repository
mkdir -p ~/dotfiles/public
cd ~/dotfiles/public
git clone --recursive https://github.com/Benoth/dotfiles.git .
chmod u+x *.sh
git config --local user.email "benoth83@gmail.com"
git config --local user.name "Benoth"

# Bootstrap (create symlinks, etc) the public repository
[[ -f ./bootstrap.sh ]] && ./bootstrap.sh || echo "No boostrap file found"

# Clone & config the private repository
mkdir -p ~/dotfiles/private
cd ~/dotfiles/private
print -n "To clone the private repository, you need to provide its address (just press Enter to abort) : "
read repo
if [[ -n "$repo" ]]; then
    git clone --recursive "$repo" .
    chmod u+x *.sh
    echo ""
    echo "Configure your repo with :"
    echo '  git config --local user.email ""'
    echo '  git config --local user.name ""'
    echo ""

    # Bootstrap (create symlinks, etc) the public repository
    [[ -f ./bootstrap.sh ]] && ./bootstrap.sh || echo "No boostrap file found"
fi

echo "All done. Re-run your session to finish the installation :)"
