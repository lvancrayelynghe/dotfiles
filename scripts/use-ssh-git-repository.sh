#!/usr/bin/env bash
#
# Switch the dotfiles repository remote from HTTPS to SSH.
set -euo pipefail

cd "${DOTFILES_PATH:?DOTFILES_PATH is not set}"
git remote remove origin
git remote add origin git@github.com:lvancrayelynghe/dotfiles.git
git push origin master
git branch --set-upstream-to=origin/master master

echo ""
echo "Do not forget to add in ~/.ssh/config :"
echo "  Host github.com"
echo "      HostName github.com"
echo "      User git"
echo "      IdentityFile ~/.ssh/id_ed25519"
echo ""
