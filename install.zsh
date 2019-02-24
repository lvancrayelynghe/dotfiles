#!/bin/zsh
export DOTFILES_PATH=~/.dotfiles/public

# Clone & config the public repository
mkdir -p ${DOTFILES_PATH}
cd ${DOTFILES_PATH}
git clone --recursive https://github.com/lvancrayelynghe/dotfiles.git .
chmod u+x *.sh
git config --local user.email "luc.vancrayelynghe@gmail.com"
git config --local user.name "Luc Vancrayelynghe"

# Bootstrap (create symlinks, etc) the public repository
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f ./bootstrap-macos.sh ]] && ./bootstrap-macos.sh || echo "No boostrap file found"
else
    [[ -f ./bootstrap-linux.sh ]] && ./bootstrap-linux.sh || echo "No boostrap file found"
fi

# Clone & config the private repository
print -n "To clone the private repository, you need to provide its **HTTPS** address (just press Enter to abort) : "
read repo
if [[ -n "$repo" ]]; then
    mkdir -p ${DOTFILES_PATH}/../private
    cd ${DOTFILES_PATH}/../private
    git clone --recursive "$repo" .
    chmod u+x *.sh
    echo ""
    echo "Configure your repo with :"
    echo '  git config --local user.email ""'
    echo '  git config --local user.name ""'
    echo ""

    # Bootstrap (create symlinks, etc) the public repository
    if [[ "$OSTYPE" == "darwin"* ]]; then
        [[ -f ./bootstrap-macos.sh ]] && ./bootstrap-macos.sh || echo "No boostrap file found"
    else
        [[ -f ./bootstrap-linux.sh ]] && ./bootstrap-linux.sh || echo "No boostrap file found"
    fi
fi

echo "All done. Re-run your session to finish the installation :)"
