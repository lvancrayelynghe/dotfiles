mkdir -p ~/bin

# install ack (grep++)
# see http://beyondgrep.com/install/
if [[ ! -e ~/bin/ack ]]; then
    curl -s http://beyondgrep.com/ack-2.14-single-file > ~/bin/ack && chmod 0755 ~/bin/ack
fi

