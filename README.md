# Dotfiles

## Requirements
- ZSH
- Git


## Installation
```
curl --silent https://raw.githubusercontent.com/Benoth/dotfiles/master/install.sh | sh
```


## What's in it?
- [Zplug](https://git.io/zplug) to manage this tools :
  - [k](https://github.com/rimraf/k) : Directory listings for zsh with git features
  - [z](https://github.com/rupa/z) : Tracks and jump to your most used directorie
  - [tl;dr](https://github.com/raylee/tldr) : Simplified and community-driven man pages
  - [Desk](https://github.com/jamesob/desk) : A lightweight workspace manager for the shell
  - [FZF](https://github.com/junegunn/fzf) : A command-line fuzzy finder
  - [ZSH Syntax highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [ack](http://beyondgrep.com/) : A tool like grep, optimized for programmers (require Perl 5)
- A lot of [ZSH](https://github.com/Benoth/dotfiles/tree/master/zsh) (lightweight) customisations, without the use of any framework, but a lot of inspiration from OhMyZsh and Prezto
- Various dotfiles for [Vim](https://github.com/Benoth/dotfiles/tree/master/vim), [Mutt](https://github.com/Benoth/dotfiles/tree/master/mutt) and [others](https://github.com/Benoth/dotfiles/tree/master/others)


## Soft requirements
Because they're used in aliases & co
- [Pygments](http://pygments.org/) : A generic syntax highlighter (apt-get install python-pygments)
- [HTTPie](https://github.com/jkbrzt/httpie) : A CLI cURL-like tool for humans (apt-get install httpie)
- [Mutt](http://www.mutt.org/) : See compilation [here](https://github.com/Benoth/dotfiles/blob/master/mutt/muttrc.symlink#L1) (or apt-get install python-pygments on recent distros)
- curl (apt-get install curl)
- pwgen for password generation (apt-get install pwgen)
- imagemagick (apt-get install imagemagick)
- ffmpeg (apt-get install ffmpeg)
- openssl (apt-get install openssl)
- cowsay and fortune for the lulz (apt-get install cowsay, fortune)


## Sources of inspiration
- [Github does dotfiles](http://dotfiles.github.io/)
- [Most starred dotfiles repos](https://github.com/search?langOverride=&language=&o=desc&q=dotfiles&repo=&s=stars&start_value=1&type=Repositories&utf8=%E2%9C%93)
- [Prezto](https://github.com/sorin-ionescu/prezto)
- [Oh My ESH](https://github.com/robbyrussell/oh-my-zsh)
- [Oh My Git](https://github.com/arialdomartini/oh-my-git)
- [Agnoster's ZSH theme](https://gist.github.com/agnoster/3712874)

