#!/bin/bash

cd ~/dotfiles
git remote rm origin
git remote add origin git@github.com:Benoth/dotfiles.git
git push origin master

echo ""
echo "Do not forget to add in ~/.ssh/config :"
echo "  Host github.com"
echo "      HostName github.com"
echo "      User git"
echo "      IdentityFile ~/.ssh/keys/personnal-key.rsa"
echo ""

