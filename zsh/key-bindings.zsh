#!/usr/bin/env zsh

# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Standard-Widgets

# Use human-friendly identifiers.
zmodload zsh/terminfo
typeset -gA keymap
keymap=(
  'Control'      '\C-'
  'ControlLeft'  '^[[1;5D'
  'ControlRight' '^[[1;5C'
  'Escape'       '\e'
  'Meta'         '\M-'
  'Backspace'    "^?"
  'Delete'       "^[[3~"
  'Del'          "$terminfo[kdch1]"
  'F1'           "$terminfo[kf1]"
  'F2'           "$terminfo[kf2]"
  'F3'           "$terminfo[kf3]"
  'F4'           "$terminfo[kf4]"
  'F5'           "$terminfo[kf5]"
  'F6'           "$terminfo[kf6]"
  'F7'           "$terminfo[kf7]"
  'F8'           "$terminfo[kf8]"
  'F9'           "$terminfo[kf9]"
  'F10'          "$terminfo[kf10]"
  'F11'          "$terminfo[kf11]"
  'F12'          "$terminfo[kf12]"
  'Insert'       "$terminfo[kich1]"
  'Home'         "$terminfo[khome]"
  'End'          "$terminfo[kend]"
  'PageUp'       "$terminfo[kpp]"
  'PageDown'     "$terminfo[knp]"
  'Up'           "$terminfo[kcuu1]"
  'Down'         "$terminfo[kcud1]"
  'Left'         "$terminfo[kcub1]"
  'Right'        "$terminfo[kcuf1]"
  'BackTab'      "$terminfo[kcbt]"
)

# Set empty $keymap values to an invalid UTF-8 sequence to induce silent bindkey failure.
for key in "${(k)keymap[@]}"; do
  if [[ -z "$keymap[$key]" ]]; then
    keymap[$key]='�'
  fi
done

# Make sure that the terminal is in application mode when zle is active, since only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  function zle-line-init() {
    echoti smkx
  }
  function zle-line-finish() {
    echoti rmkx
  }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# Prepare edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line

# General key mapping
bindkey -e                                                               # Use emacs key bindings
bindkey ' ' magic-space                                                  # [Space] - do history expansion
bindkey "$keymap[Control]R" history-incremental-pattern-search-backward  # [Ctrl-r] - Search backward incrementally for a specified string. The string may begin with ^ to anchor the search to the beginning of the line.
bindkey "$keymap[Control]L" clear-screen                                 # [Ctrl-r] - Clear the screen
bindkey "$keymap[PageUp]" up-line-or-history                             # [PageUp] - Up a line of history
bindkey "$keymap[PageDown]" down-line-or-history                         # [PageDown] - Down a line of history
bindkey "$keymap[Up]" up-line-or-search                                  # [Up-Arrow] - start typing : fuzzy find history forward
bindkey "$keymap[Down]" down-line-or-search                              # [Down-Arrow] - start typing : fuzzy find history backward
bindkey "$keymap[BackTab]" reverse-menu-complete                         # [Shift-Tab] - move through the completion menu backwards
bindkey "$keymap[ControlLeft]" backward-word                             # [Ctrl-LeftArrow] - move backward one word
bindkey "$keymap[ControlRight]" forward-word                             # [Ctrl-RightArrow] - move forward one word
bindkey "$keymap[Home]" beginning-of-line                                # [Home] - go to beginning of line
bindkey "$keymap[End]"  end-of-line                                      # [End] - go to end of line
bindkey "$keymap[Backspace]" backward-delete-char                        # [Backspace] - delete backward
bindkey "$keymap[Del]" delete-char                                       # [Delete] - delete forward
bindkey "$keymap[Control]X$keymap[Control]E" edit-command-line           # [Ctrl-x][Ctrl-e] Edit the current command line in $EDITOR

bindkey "$keymap[Escape]w" kill-region                                   # [Esc-w] - Kill from the cursor to the mark
bindkey -s "$keymap[Escape]l" 'll\n'                                     # [Esc-l] - run command: ll
bindkey -s "$keymap[Escape]d" 'd\n'                                      # [Esc-d] - run command: d
bindkey -s "$keymap[Escape]p" 'pwd\n'                                    # [Esc-p] - run command: pwd

# Fix numeric keypad
bindkey -s "^[Op" "0"  # [NumPad 0]
bindkey -s "^[On" "."  # [NumPad .]
bindkey -s "^[OM" "^M" # [NumPad Enter]
bindkey -s "^[Oq" "1"  # [NumPad 1]
bindkey -s "^[Or" "2"  # [NumPad 2]
bindkey -s "^[Os" "3"  # [NumPad 3]
bindkey -s "^[Ot" "4"  # [NumPad 4]
bindkey -s "^[Ou" "5"  # [NumPad 5]
bindkey -s "^[Ov" "6"  # [NumPad 6]
bindkey -s "^[Ow" "7"  # [NumPad 7]
bindkey -s "^[Ox" "8"  # [NumPad 8]
bindkey -s "^[Oy" "9"  # [NumPad 9]
bindkey -s "^[OQ" "/"  # [NumPad /]
bindkey -s "^[OR" "*"  # [NumPad *]
bindkey -s "^[OS" "-"  # [NumPad -]
bindkey -s "^[Ol" "+"  # [NumPad +]

# Fix other keys
bindkey '[1~' beginning-of-line       # [Home]
bindkey '[4~' end-of-line             # [End]
bindkey '[3~' delete-char             # [Del]
bindkey '[2~' overwrite-mode          # [Insert]
bindkey '[5~' history-search-backward # [PgUp]
bindkey '[6~' history-search-forward  # [PgDn]


# Sudo last command
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    [[ $BUFFER != sudo\ * ]] && LBUFFER="sudo $LBUFFER"
}
zle -N sudo-command-line
# Defined shortcut keys: [Esc][Esc]
bindkey "$keymap[Escape]$keymap[Escape]" sudo-command-line


# Snippets
autoload -U modify-current-argument
typeset -A snippets
snippets=(
  e /etc
  u /usr
  b /usr/bin
)
expand-snippet() {
  modify-current-argument '${snippets[${ARG}]}'
}
zle -N expand-snippet
# Defined shortcut keys: [Ctrl]-v
bindkey "$keymap[Escape]V" expand-snippet
