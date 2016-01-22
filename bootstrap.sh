#!/usr/bin/env bash

declare -A SYMLINKS=(
    ['bash/bashrc']='.bashrc'
    ['bash/inputrc']='.inputrc'
    ['bash/profile']='.profile'
    ['desk/web-project.sh']='.desk/web-project.sh'
    ['mutt/muttrc']='.muttrc'
    ['others/ackrc']='.ackrc'
    ['others/bcrc']='.bcrc'
    ['others/curlrc']='.curlrc'
    ['others/dircolors']='.dircolors'
    ['others/gemrc']='.gemrc'
    ['others/gitattributes']='.gitattributes'
    ['others/gitconfig']='.gitconfig'
    ['others/my.cnf']='.my.cnf'
    ['others/nanorc']='.nanorc'
    ['others/sshrc']='.sshrc'
    ['others/tmux.conf']='.tmux.conf'
    ['others/wgetrc']='.wgetrc'
    ['others/zlogin']='.zlogin'
    ['vim/vimrc']='.vimrc'
    ['vim/vim']='.vim'
    ['zsh/zlogin']='.zlogin'
    ['zsh/zshenv']='.zshenv'
    ['zsh/zshrc_brutus']='.zshrc_brutus'
    ['zsh/zshrc_homestead']='.zshrc_homestead'
    ['zsh/zshrc']='.zshrc'
)

####################################################################################
####################################################################################
####################################################################################

DOTFILES_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

user()    { printf "\r  [ \033[0;33m?\033[0m ] $1 " ; }
success() { printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n" ; }
fail()    { printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n" ; echo '' ; exit ; }
link_file() { mkdir -p `dirname $2` ; ln -s $1 $2 ; success "linked $1 to $2" ; }
copy_file() { mkdir -p `dirname $2` ; cp -r $1 $2 ; success "copied $1 to $2" ; }

echo 'Installing public dotfiles...'

do_symlinks() {
    echo 'Symlinks...'
    
    # remove dead symlinks
    for i in $(file .* | grep broken | cut -d : -f 1); do rm $i; done
    
    overwrite_all=false
    backup_all=false
    skip_all=false
    for K in "${!SYMLINKS[@]}"; do
        source="${DOTFILES_ROOT}/${K}"
        dest="${HOME}/${SYMLINKS[$K]}"

        if [ ! -f $source ] && [ ! -d $source ]; then
            fail "File $source does not exists"
        fi

        if [ -f $dest ] || [ -d $dest ]; then
          overwrite=false
          backup=false
          skip=false
          if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
            user "File already exists: `basename $dest`, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
            read -n 1 action

            case "$action" in
              o )
                overwrite=true;;
              O )
                overwrite_all=true;;
              b )
                backup=true;;
              B )
                backup_all=true;;
              s )
                skip=true;;
              S )
                skip_all=true;;
              * )
                ;;
            esac
          fi

          if [ "$overwrite" == "true" ] || [ "$overwrite_all" == "true" ]; then
            rm -rf $dest
            success "removed $dest"
          fi

          if [ "$backup" == "true" ] || [ "$backup_all" == "true" ]; then
            mv $dest $dest\.backup
            success "moved $dest to $dest.backup"
          fi

          if [ "$skip" == "false" ] && [ "$skip_all" == "false" ]; then
            link_file $source $dest
          else
            success "skipped $source"
          fi

        else
          link_file $source $dest
        fi
    done
}

do_symlinks
