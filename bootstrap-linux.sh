#!/usr/bin/env bash

declare -A COPIES=(
    ['bash/bashrc']='.bashrc'
    ['zsh/zshenv']='.zshenv'
    ['others/albert.conf']='.config/albert/albert.conf'
    ['others/cmus_autosave']='.config/cmus/autosave'
    ['others/ssh_config']='.ssh/config'
    ['others/tilda_config_0']='.config/tilda/config_0'
)

declare -A SYMLINKS=(
    ['bash/inputrc']='.inputrc'
    ['bash/profile']='.profile'
    ['zsh/zshrc']='.zshrc'
    ['scripts/chromium-focus-and-new-tab.sh']='bin/chromium-focus-and-new-tab'
    ['scripts/cmus-window.sh']='bin/cmus-window'
    ['scripts/create-desk.sh']='bin/create-desk'
    ['scripts/lights-on.sh']='bin/lights-on'
    ['scripts/move-to-next-monitor.sh']='bin/move-to-next-monitor'
    ['scripts/numlock.sh']='bin/numlock'
    ['scripts/popup-calendar.sh']='bin/popup-calendar'
    ['scripts/rec-gif.sh']='bin/rec-gif'
    ['scripts/screenlock.sh']='bin/screenlock'
    ['scripts/switch-or-run.sh']='bin/switch-or-run'
    ['scripts/systray.sh']='bin/systray'
    ['vim/vim']='.vim'
    ['vim/vimrc']='.vimrc'
    ['xresources']='.config/xresources'
    ['xresources/Xresources']='.Xresources'
    ['bspwm']='.config/bspwm'
    ['conky']='.config/conky'
    ['sxhkd']='.config/sxhkd'
    ['geany/geany.conf']='.config/geany/geany.conf'
    ['geany/keybindings.conf']='.config/geany/keybindings.conf'
    ['geany/monokai.conf']='.config/geany/colorschemes/monokai.conf'
    ['luakit']='.config/luakit'
    ['mutt/muttrc']='.muttrc'
    ['others/ackrc']='.ackrc'
    ['others/altyo_config-standalone.ini']='.config/altyo/config-standalone.ini'
    ['others/altyo_config.ini']='.config/altyo/config.ini'
    ['others/bcrc']='.bcrc'
    ['others/compton.conf']='.config/compton.conf'
    ['others/curlrc']='.curlrc'
    ['others/cvsignore']='.cvsignore'
    ['others/dircolors']='.dircolors'
    ['others/dunstrc']='.config/dunst/dunstrc'
    ['others/gemrc']='.gemrc'
    ['others/git-templates']='.git-templates'
    ['others/gitattributes']='.gitattributes'
    ['others/gitignore-global']='.gitignore-global'
    ['others/gitconfig']='.gitconfig'
    ['others/gtkrc-2.0']='.gtkrc-2.0'
    ['others/indicator-sysmonitor.json']='.indicator-sysmonitor.json'
    ['others/lesskey']='.lesskey'
    ['others/mimeapps.list']='.local/share/applications/mimeapps.list'
    ['others/my.cnf']='.my.cnf'
    ['others/nanorc']='.nanorc'
    ['others/notify-osd']='.notify-osd'
    ['others/pcmanfm.conf']='.config/pcmanfm/default/pcmanfm.conf'
    ['others/remarkable.settings']='.remarkable/remarkable.settings'
    ['others/sift.conf']='.sift.conf'
    ['others/spacemacs']='.spacemacs'
    ['others/sshrc']='.sshrc'
    ['others/sshrc.d']='.sshrc.d'
    ['others/tmux.conf']='.tmux.conf'
    ['others/wgetrc']='.wgetrc'
    ['qutebrowser/keys.conf']='.config/qutebrowser/keys.conf'
    ['qutebrowser/qutebrowser.conf']='.config/qutebrowser/qutebrowser.conf'
    ['ranger/commands.py']='.config/ranger/commands.py'
    ['ranger/rc.conf']='.config/ranger/rc.conf'
    ['sublime-text-3/Packages/ChromeRemoteReload.py']='.config/sublime-text-3/Packages/ChromeRemoteReload.py'
    ['sublime-text-3/Packages/CommandOnSave']='.config/sublime-text-3/Packages/CommandOnSave'
    ['sublime-text-3/Packages/PHP']='.config/sublime-text-3/Packages/PHP'
    ['sublime-text-3/Packages/Snippets']='.config/sublime-text-3/Packages/Snippets'
    ['sublime-text-3/Packages/User/AdvancedNewFile.sublime-settings']='.config/sublime-text-3/Packages/User/AdvancedNewFile.sublime-settings'
    ['sublime-text-3/Packages/User/anmol.tmTheme']='.config/sublime-text-3/Packages/User/anmol.tmTheme'
    ['sublime-text-3/Packages/User/CommandOnSave.sublime-settings']='.config/sublime-text-3/Packages/User/CommandOnSave.sublime-settings'
    ['sublime-text-3/Packages/User/Default.sublime-keymap.pc']='.config/sublime-text-3/Packages/User/Default.sublime-keymap'
    ['sublime-text-3/Packages/User/Default.sublime-mousemap']='.config/sublime-text-3/Packages/User/Default.sublime-mousemap'
    ['sublime-text-3/Packages/User/Emmet.sublime-settings']='.config/sublime-text-3/Packages/User/Emmet.sublime-settings'
    ['sublime-text-3/Packages/User/markdown.css']='.config/sublime-text-3/Packages/User/markdown.css'
    ['sublime-text-3/Packages/User/MarkdownPreview.sublime-settings']='.config/sublime-text-3/Packages/User/MarkdownPreview.sublime-settings'
    ['sublime-text-3/Packages/User/Package Control.sublime-settings']='.config/sublime-text-3/Packages/User/Package Control.sublime-settings'
    ['sublime-text-3/Packages/User/PHP Companion.sublime-settings']='.config/sublime-text-3/Packages/User/PHP Companion.sublime-settings'
    ['sublime-text-3/Packages/User/Preferences.sublime-settings']='.config/sublime-text-3/Packages/User/Preferences.sublime-settings'
)

####################################################################################
####################################################################################
####################################################################################

DOTFILES_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

user()    { printf "\r  [ \033[0;33m?\033[0m ] $1 " ; }
success() { printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n" ; }
fail()    { printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n" ; echo '' ; exit ; }
link_file() { mkdir -p "`dirname "$2"`" ; ln -s "$1" "$2" ; success "linked $1 to $2" ; }
copy_file() { mkdir -p "`dirname "$2"`" ; cp -r "$1" "$2" ; success "copied $1 to $2" ; }

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

        if [ ! -f "$source" ] && [ ! -d "$source" ]; then
            fail "File $source does not exists"
        fi

        if [ -f "$dest" ] || [ -d "$dest" ]; then
          overwrite=false
          backup=false
          skip=false
          if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
            user "File already exists: $dest, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
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
            rm -rf "$dest"
            success "removed $dest"
          fi

          if [ "$backup" == "true" ] || [ "$backup_all" == "true" ]; then
            mv "$dest" "$dest\.backup"
            success "moved $dest to $dest.backup"
          fi

          if [ "$skip" == "false" ] && [ "$skip_all" == "false" ]; then
            link_file "$source" "$dest"
          else
            success "skipped $source"
          fi

        else
          if [ -L "$dest" ]; then
            rm "$dest"
          fi
          link_file "$source" "$dest"
        fi
    done
}

do_copies() {
    echo 'Copying...'

    overwrite_all=false
    backup_all=false
    skip_all=false
    for K in "${!COPIES[@]}"; do
        source="${DOTFILES_ROOT}/${K}"
        dest="${HOME}/${COPIES[$K]}"

        if [ ! -f "$source" ] && [ ! -d "$source" ]; then
            fail "File $source does not exists"
        fi

        if [ -f "$dest" ] || [ -d "$dest" ]; then
          overwrite=false
          backup=false
          skip=false
          if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
            user "File already exists: $dest, what do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
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
            rm -rf "$dest"
            success "removed $dest"
          fi

          if [ "$backup" == "true" ] || [ "$backup_all" == "true" ]; then
            mv "$dest" "$dest\.backup"
            success "moved $dest to $dest.backup"
          fi

          if [ "$skip" == "false" ] && [ "$skip_all" == "false" ]; then
            copy_file "$source" "$dest"
          else
            success "skipped $source"
          fi

        else
          if [ -L "$dest" ]; then
            rm "$dest"
          fi
          copy_file "$source" "$dest"
        fi
    done
}

do_symlinks
do_copies
