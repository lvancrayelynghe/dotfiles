#!/bin/sh

echo "# ALIASES" >| ~/dotfiles/others/sshrc.symlink
cat ~/dotfiles/zsh/aliases.zsh \
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
>> ~/dotfiles/others/sshrc.symlink

echo "" >> ~/dotfiles/others/sshrc.symlink
echo "" >> ~/dotfiles/others/sshrc.symlink
echo "" >> ~/dotfiles/others/sshrc.symlink

echo "# FUNCTIONS" >> ~/dotfiles/others/sshrc.symlink
cat ~/dotfiles/zsh/functions.zsh \
| perl -p0e 's/\n# Commands usage statistics.*?}\n//s' \
| perl -p0e 's/\n# Find files using ZSH globbing.*?}\n//s' \
| perl -p0e 's/\n# Find and replace in current dir.*?}\n//s' \
| perl -p0e 's/\n# Make a port .*?}\n//s' \
| perl -p0e 's/\n# Restore ports speed.*?}\n//s' \
| perl -p0e 's/\n# Animated gifs from any video.*?}\n//s' \
| perl -p0e 's/\n# Because Metroid.*?}\n//s' \
>> ~/dotfiles/others/sshrc.symlink

echo "" >> ~/dotfiles/others/sshrc.symlink
echo "" >> ~/dotfiles/others/sshrc.symlink
echo "" >> ~/dotfiles/others/sshrc.symlink

echo "# BASHRC" >> ~/dotfiles/others/sshrc.symlink
cat ~/dotfiles/bash/bashrc.symlink \
| perl -p0e 's/\nif.*?fi\n//s' \
| grep -v "mkdir" \
>> ~/dotfiles/others/sshrc.symlink
