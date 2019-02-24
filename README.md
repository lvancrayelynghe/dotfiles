# Dotfiles

## Requirements
- ZSH and Git on Ubuntu
- [Babun](http://babun.github.io/) on Windows


## Installation
```
export DOTFILES_PATH=~/.dotfiles/public
wget https://raw.githubusercontent.com/lvancrayelynghe/dotfiles/master/install.zsh && chmod u+x install.zsh && ./install.zsh && rm install.zsh
```


## What's in it?
- [k](https://github.com/rimraf/k) : Directory listings for zsh with git features
- [z](https://github.com/knu/z) : Tracks and jump to your most used directories (knu fork)
- [tl;dr](https://github.com/raylee/tldr) : Simplified and community-driven man pages
- [Desk](https://github.com/jamesob/desk) : A lightweight workspace manager for the shell
- [FZF](https://github.com/junegunn/fzf) : A command-line fuzzy finder
- [sshrc](https://github.com/Russell91/sshrc) : Bring your dotfiles with you when you ssh
- [cdiff](https://github.com/ymattw/cdiff) : Term based tool to view colored, incremental diff
- [ZSH Syntax highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [git-cheat](https://github.com/0xBX/git-cheat)
- [ack](http://beyondgrep.com/) : A tool like grep, optimized for programmers (require Perl 5)
- [sift](https://sift-tool.org/) : A fast and powerful alternative to grep
- A lot of [ZSH](https://github.com/lvancrayelynghe/dotfiles/tree/master/zsh) (lightweight) customisations, without the use of any framework, but a lot of inspiration from OhMyZsh and Prezto
- Various dotfiles for [Vim](https://github.com/lvancrayelynghe/dotfiles/tree/master/vim), [Mutt](https://github.com/lvancrayelynghe/dotfiles/tree/master/mutt) and [others](https://github.com/lvancrayelynghe/dotfiles/tree/master/others)


## Soft requirements
Because they're used in aliases & co
- [Pygments](http://pygments.org/) : A generic syntax highlighter (apt-get install python-pygments)
- [HTTPie](https://github.com/jkbrzt/httpie) : A CLI cURL-like tool for humans (apt-get install httpie)
- [Mutt](http://www.mutt.org/) : See compilation [here](https://github.com/lvancrayelynghe/dotfiles/blob/master/mutt/muttrc#L1) (or apt-get install mutt on recent distros)
- curl (apt-get install curl)
- pwgen for password generation (apt-get install pwgen)
- imagemagick (apt-get install imagemagick)
- ffmpeg (apt-get install ffmpeg)
- openssl (apt-get install openssl)
- trash-cli (apt-get install trash-cli)
- play (apt-get install sox)
- cowsay and fortune for the lulz (apt-get install cowsay fortune)


## Enable powerline theme and git status in prompt
```
echo "export LC_POWERLINE=true" > ".zshrc_`hostname`"
echo "export ZSH_VCS_INFO=true" >> ".zshrc_`hostname`"
```


## Sources of inspiration
- [Github does dotfiles](http://dotfiles.github.io/)
- [Most starred dotfiles repos](https://github.com/search?langOverride=&language=&o=desc&q=dotfiles&repo=&s=stars&start_value=1&type=Repositories&utf8=%E2%9C%93)
- [Prezto](https://github.com/sorin-ionescu/prezto)
- [Oh My ZSH](https://github.com/robbyrussell/oh-my-zsh)
- [Oh My Git](https://github.com/arialdomartini/oh-my-git)
- [MiniVim](https://github.com/sd65/MiniVim)
- [noctuid/dotfiles](https://github.com/noctuid/dotfiles) and [unbalancedparentheses/dotfiles](https://github.com/unbalancedparentheses/dotfiles) for keyboard workflow ideas
