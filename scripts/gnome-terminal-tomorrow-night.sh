#!/usr/bin/env bash
#
# See https://terminal.sexy/#HR8hxcjGHR8hsDo-d4kAtYwpKjXSfUCwPIpukpWTlpiWzGZmtb1o8MZ0gaK-spS7ir637Ovs
# Source https://github.com/chriskempson/tomorrow-theme/blob/master/Gnome-Terminal/setup-theme.sh
#

[[ -z "$PROFILE_NAME" ]] && PROFILE_NAME=TomorrowNight
[[ -z "$PROFILE_SLUG" ]] && PROFILE_SLUG=TomorrowNight
[[ -z "$DCONF" ]] && DCONF=dconf
[[ -z "$UUIDGEN" ]] && UUIDGEN=uuidgen

dset() {
  local key="$1"; shift
  local val="$1"; shift

  if [[ "$type" == "string" ]]; then
      val="'$val'"
  fi

  "$DCONF" write "$PROFILE_KEY/$key" "$val"
}

# because dconf still doesn't have "append"
dlist_append() {
  local key="$1"; shift
  local val="$1"; shift

  local entries="$(
    {
      "$DCONF" read "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
      echo "'$val'"
    } | head -c-1 | tr "\n" ,
  )"

  "$DCONF" write "$key" "[$entries]"
}

# Newest versions of gnome-terminal use dconf
if which "$DCONF" > /dev/null 2>&1; then
    [[ -z "$BASE_KEY_NEW" ]] && BASE_KEY_NEW=/org/gnome/terminal/legacy/profiles:

    if [[ -n "`$DCONF list $BASE_KEY_NEW/`" ]]; then
        if which "$UUIDGEN" > /dev/null 2>&1; then
            PROFILE_SLUG=`uuidgen`
        fi

        if [[ -n "`$DCONF read $BASE_KEY_NEW/default`" ]]; then
          DEFAULT_SLUG=`$DCONF read $BASE_KEY_NEW/default | tr -d \'`
        else
          DEFAULT_SLUG=`$DCONF list $BASE_KEY_NEW/ | grep '^:' | head -n1 | tr -d :/`
        fi

        DEFAULT_KEY="$BASE_KEY_NEW/:$DEFAULT_SLUG"
        PROFILE_KEY="$BASE_KEY_NEW/:$PROFILE_SLUG"

        # copy existing settings from default profile
        $DCONF dump "$DEFAULT_KEY/" | $DCONF load "$PROFILE_KEY/"

        # add new copy to list of profiles
        dlist_append $BASE_KEY_NEW/list "$PROFILE_SLUG"

        # update profile values with theme options
        dset visible-name "'$PROFILE_NAME'"
        dset palette "['#2d2d2d', '#b03a3e', '#778900', '#b58c29', '#2a35d2', '#7d40b0', '#3c8a6e', '#929593', '#969896', '#cc6666', '#b5bd68', '#f0c674', '#81a2be', '#b294bb', '#8abeb7', '#ecebec']"
        dset background-color "'#2d2d2d'"
        dset foreground-color "'#cccccc'"
        dset bold-color "'#cccccc'"
        dset bold-color-same-as-fg "false"
        dset use-theme-colors "false"

        # Add by Benoth - Change font to Hack
        dset font "'Hack 10'"
        dset use-system-font "false"

        # Add by Benoth - Force maximised
        dset default-size-columns "256"
        dset default-size-rows "256"

        unset PROFILE_NAME
        unset PROFILE_SLUG
        unset DCONF
        unset UUIDGEN
        exit 0
    fi
fi

# Fallback for Gnome 2 and early Gnome 3
[[ -z "$GCONFTOOL" ]] && GCONFTOOL=gconftool
[[ -z "$BASE_KEY" ]] && BASE_KEY=/apps/gnome-terminal/profiles

PROFILE_KEY="$BASE_KEY/$PROFILE_SLUG"

gset() {
  local type="$1"; shift
  local key="$1"; shift
  local val="$1"; shift

  "$GCONFTOOL" --set --type "$type" "$PROFILE_KEY/$key" -- "$val"
}

# because gconftool doesn't have "append"
glist_append() {
  local type="$1"; shift
  local key="$1"; shift
  local val="$1"; shift

  local entries="$(
    {
      "$GCONFTOOL" --get "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
      echo "$val"
    } | head -c-1 | tr "\n" ,
  )"

  "$GCONFTOOL" --set --type list --list-type $type "$key" "[$entries]"
}

# append the Tomorrow profile to the profile list
glist_append string /apps/gnome-terminal/global/profile_list "$PROFILE_SLUG"

gset string visible_name "$PROFILE_NAME"
gset string palette "#2d2d2d:#b03a3e:#778900:#b58c29:#2a35d2:#7d40b0:#3c8a6e:#929593:#969896:#cc6666:#b5bd68:#f0c674:#81a2be:#b294bb:#8abeb7:#ecebec"
gset string background_color "#2d2d2d"
gset string foreground_color "#cccccc"
gset string bold_color "#cccccc"
gset bool   bold_color_same_as_fg "false"
gset bool   use_theme_colors "false"
gset bool   use_theme_background "false"

# Add by Benoth - Change font to Hack
gset string font "Hack 10"
gset bool   use_system_font "false"

# Add by Benoth - Force maximised
gset string default-size-columns "256"
gset string default-size-rows "256"

unset PROFILE_NAME
unset PROFILE_SLUG
unset DCONF
unset UUIDGEN
