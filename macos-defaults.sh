#!/usr/bin/env bash
#
# macOS system preferences. Run manually after a fresh install:
#   ./macos-defaults.sh [hostname]
# Some settings need a logout/restart to apply.
#
# Trimmed 2026 rewrite of the old install/00-osx.sh: sections targeting
# removed macOS features (Dashboard, containerized Safari prefs, rcd/gamed,
# subpixel font smoothing, nvram on Apple Silicon) were dropped.
set -uo pipefail

[ "$(uname)" = Darwin ] || { echo "macOS only"; exit 1; }

# Close System Settings to prevent it from overriding our changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# Keep sudo alive for the duration of the script
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General                                                                     #
###############################################################################

# Hostname (optional first argument)
if [ -n "${1:-}" ]; then
    sudo scutil --set ComputerName "$1"
    sudo scutil --set HostName "$1"
    sudo scutil --set LocalHostName "$1"
fi

# Disable guest access
sudo defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool false
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# Scrollbars visible when scrolling only
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Expand save and print panels by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable smart quotes/dashes/capitalization/spell-correction (annoying when coding)
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Input: trackpad, keyboard, language                                         #
###############################################################################

# Tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Two-finger / corner secondary click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Full keyboard access (tab through all controls)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Fast key repeat, no press-and-hold accent popup
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat -int 3
defaults write NSGlobalDomain InitialKeyRepeat -int 20

# Language, units, timezone
defaults write NSGlobalDomain AppleLanguages -array "fr" "en"
defaults write NSGlobalDomain AppleLocale -string "fr_FR@currency=EUR"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
sudo systemsetup -settimezone "Europe/Paris" > /dev/null

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Screenshots: PNG on the Desktop, no window shadow
defaults write com.apple.screencapture location -string "${HOME}/Desktop"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

# Show drives and servers on the Desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Don't warn when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# List view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show all extensions, status bar, path bar, folders first
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Don't litter network/USB volumes with .DS_Store
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disk images: skip verification, open a window on mount
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Expanded info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

# Show ~/Library
chflags nohidden ~/Library

###############################################################################
# Dock & hot corners                                                          #
###############################################################################

defaults write com.apple.dock tilesize -int 36
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock expose-group-by-app -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0
defaults write com.apple.dock showhidden -bool true

# Hot corners: top-right = Mission Control, bottom-left = Desktop, bottom-right = App windows
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 4
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 3
defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Apps: Terminal, TextEdit, Activity Monitor, Mail, App Store                 #
###############################################################################

defaults write com.apple.terminal SecureKeyboardEntry -bool true
defaults write com.apple.Terminal ShowLineMarks -int 0

# TextEdit: plain text, UTF-8
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# Automatic software updates
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

###############################################################################
# Menu bar                                                                    #
###############################################################################
#
# Captured from a configured machine (macOS 26.5 Tahoe). Only what follows is
# reachable from a script — the block closing this section documents the large
# part of the menu bar that is not, and has to be redone by hand.
#
# Two reproducible mechanisms, and they are not the same thing:
#   - Control Center modules, stored as ints in the ByHost domain.
#   - AppKit status items pulled out of the menu bar with cmd-drag, persisted
#     as "NSStatusItem Visible <autosaveName>" in the owning app's own domain.
# Types below were read back with `defaults read-type`.
#
# A third-party app must be QUIT before its line runs: cfprefsd serves a
# running app its cached domain and rewrites the file when the app exits,
# silently reverting the write.

# Control Center modules (ByHost). Observed on this Mac: 18 = shown in the menu
# bar, 8 = not shown. Any module absent from this list is left at its default.
defaults -currentHost write com.apple.controlcenter FocusModes -int 8
defaults -currentHost write com.apple.controlcenter ScreenMirroring -int 8
defaults -currentHost write com.apple.controlcenter VoiceControl -int 8
defaults -currentHost write com.apple.controlcenter SolariumBentoBox -int 8

# System items that carry their own switch instead
defaults write com.apple.controlcenter "NSStatusItem Visible FaceTime" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.airplay showInMenuBarIfPresent -bool false
# Input source menu (the flag)
defaults write com.apple.TextInputMenuAgent "NSStatusItem Visible Item-0" -bool false

# Third-party items pulled out of the menu bar with cmd-drag. The autosave
# name is assigned by AppKit in creation order, so "Item-0" is only meaningful
# for an app that creates exactly one status item.
defaults write com.raycast.macos "NSStatusItem Visible raycastIcon" -bool false
defaults write com.raycast.macos "NSStatusItem Visible Item-1" -bool false
defaults write com.knollsoft.Hyperkey "NSStatusItem Visible Item-0" -bool false

# Third-party items removed through the app's own preference, which is the
# better lever: the status item is never instantiated at all
defaults write com.knollsoft.Rectangle hideMenubarIcon -bool true
defaults write com.knollsoft.Hyperkey hideMenuBarIcon -bool true
defaults write org.hammerspoon.Hammerspoon MJShowMenuIconKey -bool false

# NOT reproducible from here — redo by hand on a new machine
# ----------------------------------------------------------
# System Settings > Menu Bar lists every app that has ever declared a status
# item, one switch each. Those switches do control the icon, and take effect
# immediately — but their state is stored nowhere a script can reach. Checked
# on 2026-08-15 by snapshotting all 1156 preference domains (standard and
# ByHost) around a single toggle: nothing moved, there nor in
# /Library/Preferences, backgrounditems.btm, ~/Library/Application Support, or
# any file ControlCenter holds open. Most likely a TCC-style protected store,
# unreadable without full disk access.
#
# Switched off by hand in that pane, to redo:
#   1Password, ClickUp, Discord, Espanso, FluidVoice, Gemini, Google Drive,
#   Harvest, Hidden Bar, IPdivaClientExecutable, LibreOffice, macshot,
#   MacWhisper, Ollama, OrbStack, Rectangle, ScriptMonitor, Vivaldi
# Left on: Hammerspoon, Itsycal.
#
# Also deliberately not captured:
#   - com.apple.controlcenter "NSStatusItem Visible Item-0" ... "Item-9": ten
#     opaque positional names left by the Tahoe menu bar migration
#     (HasAttemptedMenuBarWorkflowMigration). They do not track that pane —
#     they stayed false while an app was switched back on — and map to nothing
#     identifiable, so replaying them would hide arbitrary items.
#   - org.p0deje.Maccy, com.jordanbaird.Ice: stale domains, apps not installed.
#   - macshot and MacWhisper: "NSStatusItem VisibleCC" = moved into Control
#     Center rather than hidden.

###############################################################################
# Apply                                                                       #
###############################################################################

for app in "cfprefsd" "ControlCenter" "Dock" "Finder" "SystemUIServer"; do
    killall "$app" &> /dev/null || true
done

echo "Done. Some changes require a logout/restart to take effect."
