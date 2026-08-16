-- Applications are addressed by bundle id here, never by name, because every
-- name-based lookup in hs.application is loose or localised, or both:
--   * `find(name)` and `get(name)` match on substrings, so "Code" also finds
--     Xcode, and when nothing matches they fall back to searching every window
--     title -- returning the browser holding a tab named after the app;
--   * `find(name, true)` is exact, but exact against the name the OS reports,
--     which is localised: Apple Music answers to "Music", not "Musique", and
--     Calendar to "Calendar", not "Calendrier";
--   * `open(name)` wants the bundle's own name, which is often not the app's:
--     "Code" launches nothing, the bundle being Visual Studio Code.app.
-- A bundle id has none of those failure modes, and `open()` takes one too
-- (application.lua:226 falls through to launchOrFocusByBundleID).
--
-- To find the id of an app, from a terminal (shell/aliases-macos.sh):
--   bundleid Vivaldi              -- by name, case insensitive
--   bundleid /Applications/X.app  -- by path
--   bundleid                      -- the frontmost application
--   bundleid -l                   -- every visible application
return {
    bruno     = 'com.usebruno.app',
    calendar  = 'com.apple.iCal',
    claude    = 'com.anthropic.claudefordesktop',
    clickup   = 'com.clickup.desktop-app',
    discord   = 'com.hnc.Discord',
    filezilla = 'org.filezilla-project.filezilla',
    finder    = 'com.apple.finder',
    ghostty   = 'com.mitchellh.ghostty',
    harvest   = 'com.getharvest.harvestxapp',
    messages  = 'com.apple.MobileSMS',
    music     = 'com.apple.Music',
    notes     = 'com.apple.Notes',
    orbstack  = 'dev.kdrag0n.MacVirt',
    sequelace = 'com.sequel-ace.sequel-ace',
    slack     = 'com.tinyspeck.slackmacgap',
    spotify   = 'com.spotify.client',
    sublime   = 'com.sublimetext.4',
    vivaldi   = 'com.vivaldi.Vivaldi',
    vscode    = 'com.microsoft.VSCode',
}
