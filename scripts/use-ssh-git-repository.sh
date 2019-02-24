#!/usr/bin/env bash

cd ${DOTFILES_PATH}
git remote rm origin
git remote add origin git@github.com:lvancrayelynghe/dotfiles.git
git push origin master
git branch --set-upstream-to=origin/master master

echo ""
echo "Do not forget to add in ~/.ssh/config :"
echo "  Host github.com"
echo "      HostName github.com"
echo "      User git"
echo "      IdentityFile ~/.ssh/keys/personnal-key.rsa"
echo ""
