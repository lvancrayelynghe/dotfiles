#!/bin/sh

echo "# ALIASES" >| ~/dotfiles/public/others/sshrc
cat ~/dotfiles/public/zsh/aliases.zsh \
| grep -v "shutdown" \
| grep -v "ffmpeg" \
| grep -v "desk" \
| grep -v "mutt" \
| grep -v "pygmentize" \
| grep -v "dotfiles" \
| grep -v "tableflip" \
| grep -v "find-and-replace" \
| grep -v "'k -" \
| grep -v "# Record x11" \
>> ~/dotfiles/public/others/sshrc

echo "" >> ~/dotfiles/public/others/sshrc
echo "" >> ~/dotfiles/public/others/sshrc
echo "" >> ~/dotfiles/public/others/sshrc

echo "# FUNCTIONS" >> ~/dotfiles/public/others/sshrc
cat ~/dotfiles/public/zsh/functions.zsh \
| perl -p0e 's/\n# Commands usage statistics.*?}\n//s' \
| perl -p0e 's/\n# Find files using ZSH globbing.*?}\n//s' \
| perl -p0e 's/\n# Find and replace in current dir.*?}\n//s' \
| perl -p0e 's/\n# Make a port .*?}\n//s' \
| perl -p0e 's/\n# Restore ports speed.*?}\n//s' \
| perl -p0e 's/\n# Show aliases and functions cheat-sheet.*?}\n//s' \
| perl -p0e 's/\n# Rename TV shows file.*?}\n//s' \
| perl -p0e 's/\n# Animated gifs from any video.*?}\n//s' \
| perl -p0e 's/\n# Let.*s be corporate.*?}\n//s' \
| perl -p0e 's/\n# Because Metroid.*?}\n//s' \
>> ~/dotfiles/public/others/sshrc

echo "" >> ~/dotfiles/public/others/sshrc
echo "" >> ~/dotfiles/public/others/sshrc
echo "" >> ~/dotfiles/public/others/sshrc

echo "# BASHRC" >> ~/dotfiles/public/others/sshrc
cat ~/dotfiles/public/bash/bashrc \
| perl -p0e 's/\nif.*?fi\n//s' \
| perl -p0e 's/\nif.*?fi\n//s' \
| grep -v "mkdir" \
>> ~/dotfiles/public/others/sshrc
