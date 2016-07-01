#!/usr/bin/env bash

echo "# ALIASES" >| ${DOTFILES_PATH}/others/sshrc
cat ${DOTFILES_PATH}/zsh/aliases.zsh \
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
>> ${DOTFILES_PATH}/others/sshrc

echo "" >> ${DOTFILES_PATH}/others/sshrc
echo "" >> ${DOTFILES_PATH}/others/sshrc
echo "" >> ${DOTFILES_PATH}/others/sshrc

echo "# FUNCTIONS" >> ${DOTFILES_PATH}/others/sshrc
cat ${DOTFILES_PATH}/zsh/functions.zsh \
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
>> ${DOTFILES_PATH}/others/sshrc

echo "" >> ${DOTFILES_PATH}/others/sshrc
echo "" >> ${DOTFILES_PATH}/others/sshrc
echo "" >> ${DOTFILES_PATH}/others/sshrc

echo "# BASHRC" >> ${DOTFILES_PATH}/others/sshrc
cat ${DOTFILES_PATH}/bash/bashrc \
| perl -p0e 's/\nif.*?fi\n//s' \
| perl -p0e 's/\nif.*?fi\n//s' \
| grep -v "mkdir" \
>> ${DOTFILES_PATH}/others/sshrc

cat << 'EOF' >> ${DOTFILES_PATH}/others/sshrc

export VIMINIT="let \$MYVIMRC='$SSHHOME/.sshrc.d/.vimrc' | source \$MYVIMRC"
EOF
