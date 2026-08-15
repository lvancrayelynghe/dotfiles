#!/usr/bin/env bash
#
# macOS system preferences. Run manually after a fresh install:
#   ./macos-defaults.sh [computer-name]
# Some settings need a logout or a restart to apply.
#
# Every line below WRITES. Never run this to inspect anything — read the file,
# or read the machine with `defaults read <domain> <key>`.
#
# Regenerated 2026-08-15 from the live state of this Mac (MacBookPro18,3,
# macOS 26.5 Tahoe, build 25F71), replacing values inherited from a 2021
# install that no longer matched anything. Three rules produced this file:
#
#   - An active line reproduces a value this Mac actually has. Nothing was
#     kept on the strength of its original intent alone.
#   - A commented-out line is a setting the previous version forced and that
#     this Mac leaves at the macOS default. The value shown is the old one:
#     uncomment to opt back in, deliberately.
#   - Keys that no longer exist on Tahoe were deleted. They are listed at the
#     bottom of the file, with how that was established.
#
set -uo pipefail
#
# No `set -e` on purpose: one unsupported key on a future macOS would abort
# mid-run and leave the machine half-configured. `defaults` is loud on stderr,
# and the single failure that must stop us is checked explicitly below.

[ "$(uname)" = Darwin ] || { echo "macOS only"; exit 1; }

# System Settings caches the panes it has open and writes them back when it
# quits, which would silently revert part of what follows.
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# Take the admin ticket once, up front, then refresh it in the background so
# the sudo blocks further down never prompt in the middle of the run.
sudo -v || { echo "admin rights required"; exit 1; }
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

###############################################################################
# Machine identity                                                            #
###############################################################################

if [ -n "${1:-}" ]; then
    # Name shown in Finder sidebars, AirDrop and Sharing. Spaces are fine here.
    sudo scutil --set ComputerName "$1"

    # Bonjour name (<name>.local). This one rejects spaces, dots and accents,
    # so it gets a sanitised copy — the Sharing pane does the same thing.
    # Passing "$1" unfiltered is how the old script failed on any name with a
    # space in it, after it had already changed ComputerName.
    sudo scutil --set LocalHostName "$(printf '%s' "$1" | tr ' ' '-' | tr -cd 'A-Za-z0-9-')"

    # HostName is deliberately NOT set. Unset means macOS derives it from
    # DHCP/DNS, which is what this Mac does; pinning it hardcodes a name that
    # then disagrees with every network it joins.
fi

# Timezone. systemsetup requires root to read as well as to write.
sudo systemsetup -settimezone "Europe/Paris" > /dev/null

###############################################################################
# General UI                                                                  #
###############################################################################

# Dark appearance. Deleting this key — not setting it to "Light" — is what
# switches back.
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Scrollbars follow the pointing device: always with a mouse, only while
# scrolling with a trackpad.
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"

# Show every file extension in Finder.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Text substitutions. Auto-capitalisation, the double-space-to-period shortcut
# and autocorrect are off: they fight with code, paths and terminal input.
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Smart dashes and smart quotes stay ON — the old script disabled both. Typing
# French prose is the common case here, and any app that must not see them
# (terminals, editors) overrides them locally anyway.
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool true

# Unset on this Mac. NSNavPanelExpandedStateForSaveMode is still a live key;
# its print-panel counterpart is not (see the removed list at the bottom).
#defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
#defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

###############################################################################
# Input: trackpad, keyboard, language                                         #
###############################################################################
#
# Two trackpad domains exist, and both have to be written to cover both
# devices:
#   com.apple.AppleMultitouchTrackpad                    built-in trackpad
#   com.apple.driver.AppleBluetoothMultitouch.trackpad   Magic Trackpad
# The old script wrote only the Bluetooth one, so on this MacBook it was
# configuring a device that is not attached.
#
# The value types below are the ones macOS itself writes, and they are not
# consistent: Clicking is a number, TrackpadRightClick a boolean. Matching
# them keeps `defaults read-type` stable after a run.

# Tap to click: OFF. Deliberate — physical click only.
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 0

# Secondary click with two fingers, on. Bottom-corner secondary click, off.
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Three-finger drag off: it is an Accessibility setting, and it swallows the
# three-finger Mission Control swipe.
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false

# Click pressure: 0 light, 1 medium, 2 firm.
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1

# Keyboard navigation: Tab moves focus between controls. 2 is what the Tahoe
# Keyboard pane writes when the toggle is on. The old value 3 is still a valid
# value, but nothing in the current UI produces it.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# Key repeat, counted in 15 ms ticks: 2 = 30 ms between repeats,
# 25 = 375 ms before the first one.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 25

# Language and region. Modern macOS stores BCP-47 tags ("fr-FR"), not the
# legacy short codes ("fr") the old script wrote, and plain fr_FR already
# implies EUR — the "@currency=EUR" suffix was noise.
defaults write NSGlobalDomain AppleLanguages -array "fr-FR"
defaults write NSGlobalDomain AppleLocale -string "fr_FR"
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"

# Press-and-hold accent popup left at the macOS default (enabled) — needed to
# type French accents on a US layout.
#defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

###############################################################################
# Screen lock and screenshots                                                 #
###############################################################################
#
# The screen-lock delay is NOT set here any more. com.apple.screensaver
# askForPassword / askForPasswordDelay are still real keys — loginwindow and
# LockScreen.appex reference both — but Settings no longer stores the value in
# that domain, and a `defaults write` to it changes nothing. The supported
# lever is:
#   sudo sysadminctl -screenLock immediate -password -
#
# Screenshot destination (~/Desktop) and format (png) are already the macOS
# defaults, so neither is written.

# Highlight mouse clicks in screen recordings.
defaults write com.apple.screencapture showsClicks -bool true

# com.apple.screencapture style is remembered UI state (the last capture mode
# used), not a setting — a setup script should not pin it.

###############################################################################
# Finder                                                                      #
###############################################################################

# Desktop icons: externals, servers and removable media yes, internal disk no.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Column view by default. "clmv" columns, "Nlsv" list, "icnv" icons.
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Folders before files, sorted by name.
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXPreferredGroupBy -string "Name"

# New windows open on the home folder. "PfHm" is the magic value for it, and
# NewWindowTargetPath has to agree with it.
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Sidebar visible.
defaults write com.apple.finder ShowSidebar -bool true

# Which sections of the Get Info window start expanded.
# -dict-add, NOT -dict: -dict replaces the whole dictionary, so the old
# three-key write silently dropped MetaData, Preview, Name and Comments.
# "General" was one of the three, and it is not a pane name Finder knows.
defaults write com.apple.finder FXInfoPanesExpanded -dict-add \
    MetaData -bool true \
    OpenWith -bool true \
    Preview -bool true \
    Privileges -bool true \
    Name -bool false \
    Comments -bool false

# Don't scatter .DS_Store files across network shares. There is no working USB
# counterpart to this key on Tahoe (see the removed list).
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Reveal ~/Library — macOS re-hides it on every major upgrade, so this line
# still earns its place even on a machine that has run this script before.
chflags nohidden ~/Library

# Left at the macOS default here; the old script forced all of these.
#defaults write com.apple.finder ShowStatusBar -bool true
#defaults write com.apple.finder ShowPathbar -bool true
#defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
#defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # current folder
#defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

###############################################################################
# Dock, Spaces and hot corners                                                #
###############################################################################

# Icon size in points. macOS stores it as a real, hence -float.
defaults write com.apple.dock tilesize -float 38

# Auto-hide the Dock. The old script also zeroed the reveal delay and the
# animation duration; both are back at their defaults here.
defaults write com.apple.dock autohide -bool true
#defaults write com.apple.dock autohide-delay -float 0
#defaults write com.apple.dock autohide-time-modifier -float 0

# Keep Spaces in the order I arranged them, instead of reordering by most
# recent use.
defaults write com.apple.dock mru-spaces -bool false

# Hot corners. The corner key holds the action, the modifier key holds the
# modifier that must be held (0 = none):
#   1  disabled            2  Mission Control     3  Application Windows
#   4  Desktop             5  start screen saver  6  disable screen saver
#   10 display sleep      11  Launchpad          12  Notification Centre
#   13 Lock Screen        14  Quick Note
# Only the bottom-right corner is pinned, and explicitly to 1: macOS ships it
# as Quick Note, which fires constantly by accident. The other three corners
# are unset on this Mac, so they are not written — the old script claimed all
# three of them.
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0

# Mission Control window grouping. The key is "expose-group-apps" now; the old
# "expose-group-by-app" spelling is gone. Unset here, so left alone.
#defaults write com.apple.dock expose-group-apps -bool false

# Left at the macOS default; the old script set each of them.
#defaults write com.apple.dock mineffect -string "scale"
#defaults write com.apple.dock minimize-to-application -bool true
#defaults write com.apple.dock show-process-indicators -bool true
#defaults write com.apple.dock showhidden -bool true

###############################################################################
# Apps                                                                        #
###############################################################################

# Activity Monitor: no window on launch, and the process filter this Mac uses.
# Apple documents no mapping for ShowCategory; 100 is what the current install
# holds, 0 was the old script's guess.
defaults write com.apple.ActivityMonitor OpenMainWindow -bool false
defaults write com.apple.ActivityMonitor ShowCategory -int 100

# Terminal.app is not the daily driver here (Ghostty is), and TextEdit and Mail
# hold nothing worth pinning. Kept commented so the intent is not lost.
# Note: com.apple.Terminal is the real bundle id — the old script wrote
# com.apple.terminal on one line, which only works because APFS is
# case-insensitive by default.
#defaults write com.apple.Terminal SecureKeyboardEntry -bool true
#defaults write com.apple.Terminal ShowLineMarks -int 0
#defaults write com.apple.TextEdit RichText -int 0
#defaults write com.apple.TextEdit PlainTextEncoding -int 4          # UTF-8
#defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
#defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

###############################################################################
# Software updates                                                            #
###############################################################################
#
# These live in the SYSTEM domain and need sudo. The old script wrote all four
# to the user domain without sudo, where nothing reads them — four silent
# no-ops. The user domain only ever holds notification timestamps.

# Check for, download and install updates automatically, including rapid
# security responses and system data files.
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true

# App Store apps too.
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true

###############################################################################
# Sharing                                                                     #
###############################################################################

# No guest login.
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

# No guest access to SMB shares. The AFP counterpart the old script also wrote
# (com.apple.AppleFileServer guestAccess) is gone from this file: Apple removed
# the AFP server itself, and the only binary on Tahoe still reading that key is
# /usr/libexec/smb-migrate-preferences, which consumes it once at migration.
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server AllowGuestAccess -bool false

###############################################################################
# Menu bar                                                                    #
###############################################################################
#
# Captured from this machine and re-verified 2026-08-15: every line in this
# section still matches the live state. Only what follows is reachable from a
# script — the block closing this section documents the large part of the menu
# bar that is not, and has to be redone by hand.
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

# Control Center modules (ByHost). 18 = shown in the menu bar, 8 = not shown.
# Any module absent from this list is left at its default.
defaults -currentHost write com.apple.controlcenter FocusModes -int 8
defaults -currentHost write com.apple.controlcenter ScreenMirroring -int 8
defaults -currentHost write com.apple.controlcenter VoiceControl -int 8
defaults -currentHost write com.apple.controlcenter SolariumBentoBox -int 8
defaults -currentHost write com.apple.controlcenter Bluetooth -int 18
defaults -currentHost write com.apple.controlcenter Sound -int 18
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
# Timer is 2 on this Mac — neither 18 nor 8, and the meaning of 2 could not be
# established without toggling it, so it is recorded but not replayed.
#defaults -currentHost write com.apple.controlcenter Timer -int 2

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
# Switched off by hand in that pane, to redo (list re-checked 2026-08-15
# against /Applications):
#   1Password, ClickUp, Discord, Espanso, FluidVoice, Gemini, Google Drive,
#   Harvest, IPdivaClient, LibreOffice, macshot, MacWhisper, Ollama, OrbStack,
#   Rectangle, Vivaldi
# Left on: Hammerspoon, Itsycal.
# Dropped from the old list: Hidden Bar (uninstalled, and no menu-bar manager
# is wanted — icons get removed, not hidden), ScriptMonitor (not an app in
# /Applications).
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
#   - org.hammerspoon.Hammerspoon "NSStatusItem Preferred Position Item-0/1":
#     positions of the two menubar items this repo's own Lua config creates
#     (hammerspoon/caffeinate.lua, hammerspoon/layouts.lua), not stale keys.

###############################################################################
# Apply                                                                       #
###############################################################################
#
# cfprefsd first, on purpose: SIGTERM is what makes it flush its in-memory
# cache to the plists, which commits everything written above. The UI agents
# are restarted after it so they re-read from disk.

for app in "cfprefsd" "ControlCenter" "Dock" "Finder" "SystemUIServer"; do
    killall "$app" &> /dev/null || true
done

echo "Done. Some changes require a logout or a restart to take effect."

###############################################################################
# Removed 2026-08-15 — keys that no longer exist on macOS 26.5                #
###############################################################################
#
# Each of these was in the previous version and wrote to a key nothing reads
# any more. Method: search the owning binary — both architecture slices, and
# including strings inlined as x86_64 `movabs` immediates, which `strings`
# cannot see — plus all twelve slices of the dyld shared cache, accepting a
# hit only as a standalone C literal (so `SortColumn` does not match inside
# `_updateSortColumn`).
#
#   NSGlobalDomain PMPrintingExpandedStateForPrint      no hit, nor "…Print2"
#   com.apple.print.PrintingPrefs "Quit When Finished"  domain and key both gone
#   com.apple.AppleFileServer guestAccess               AFP server removed
#   com.apple.screencapture disable-shadow              no hit anywhere
#   com.apple.desktopservices DSDontWriteUSBStores      no hit; the Network
#                                                       counterpart is alive
#   com.apple.frameworks.diskimages skip-verify         only a CLI flag of
#   com.apple.frameworks.diskimages skip-verify-locked  hdiutil, never read as
#   com.apple.frameworks.diskimages skip-verify-remote  a preference
#   com.apple.finder OpenWindowForNewRemovableDisk      absent from Finder
#   com.apple.dock expose-animation-duration            absent from Dock
#   com.apple.dock expose-group-by-app                  renamed expose-group-apps
#   com.apple.ActivityMonitor SortColumn                absent from the binary
#   com.apple.ActivityMonitor SortDirection             absent from the binary
#   com.apple.mail DisableReplyAnimations               absent from Mail
#   com.apple.mail DisableSendAnimations                absent from Mail
#   com.apple.mail AddressesIncludeNameOnPasteboard     absent from Mail
#
# Verified alive and kept, against first impressions: com.apple.dock mru-spaces
# and showhidden are both inlined as immediates rather than stored as literals,
# which is why a naive `strings` sweep reports them missing.
