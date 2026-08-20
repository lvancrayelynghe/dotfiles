-- KeyCodes : http://www.hammerspoon.org/docs/hs.keycodes.html#map

local apps = require('apps')

-- By bundle id throughout, see apps.lua for why: applicationsForBundleID() is
-- exact and has no fallback, and open() takes a bundle id as readily as a name.
function launchOrSwitch(bundleID)
    local app = hs.application.applicationsForBundleID(bundleID)[1]

    if app == nil then
        hs.application.open(bundleID)
        return
    end

    -- Running with no window at all is what an application closed with cmd-W
    -- looks like -- Calendar and the other native ones stay up with nothing
    -- left -- and activate() would then bring forward an application that
    -- displays nothing. Only the application itself can make a window, through
    -- the reopen event LaunchServices sends here, the one a Dock click sends:
    -- measured, it opens Calendar's window back, and un-minimizes Sublime
    -- Text's. Finder is the exception, and stays unfixed: its desktop counts as
    -- a window of its own, so the event finds one already up and does nothing.
    -- Asked before the frontmost test on purpose -- pressing the key again has
    -- to bring the window back, not switch away to another application.
    --
    -- mainWindow() gets the last word as the only call here that reaches
    -- another Space: measured, a fullscreen window living on one answers nil to
    -- app:allWindows() and comes back from mainWindow(). Without it, an
    -- application whose only window sits on another Space, and that the window
    -- filter happens to have missed, would be sent a reopen event -- which some
    -- applications answer with a brand new window.
    local windows = switcher:appWindows(app)
    if #windows == 0 and app:mainWindow() == nil then
        hs.application.open(bundleID)
        return
    end

    if hs.application.frontmostApplication():bundleID() == bundleID then
        switcher:switchWindow(true)
        return
    end

    -- unhides and un-minimizes as needed: activate() does neither
    switcher:focusApp(app, windows)
end

-- App Bindings
for key, bundleID in pairs({
    -- first row
    ["a"] = apps.slack,
    ["z"] = apps.zed,
    ["e"] = apps.finder,
    ["r"] = apps.bruno,
    ["t"] = apps.filezilla,
    ["y"] = apps.harvest,
    -- u → free
    -- i → free
    -- o → todo.md
    ["p"] = apps.notes,

    -- second row
    ["q"] = apps.calendar,
    ["s"] = apps.sublime,
    ["d"] = apps.discord,
    ["f"] = apps.vivaldi,
    ["g"] = apps.ghostty,
    -- h → resize
    -- j → resize
    -- k → resize
    -- l → resize
    -- m → floating term

    -- third row
    -- w → free
    ["x"] = apps.clickup,
    ["c"] = apps.claude,
    ["v"] = apps.vscode,
    ["b"] = apps.sequelace,
    -- n → free
}) do
    hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, key, function()
        launchOrSwitch(bundleID)
    end)
end

-- Alt-tab replacement to go to last window
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "tab", function()
    switcher:previousWindow(false)
end)

-- Toggle fullscreen
hs.hotkey.bind({'cmd', 'alt', 'ctrl', 'shift'}, "return", function()
    local win = hs.window.focusedWindow()
    if win ~= nil then
        win:setFullScreen(not win:isFullScreen())
    end
end)

-- Close active window
hs.hotkey.bind({'cmd', 'alt', 'ctrl', 'shift'}, "q", function()
  local win = hs.window.focusedWindow()
  win:application():kill()
end)

hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "o", function() hs.execute("/opt/homebrew/bin/subl ~/Library/Mobile\\ Documents/com~apple~CloudDocs/todo.md") end)

hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "h", function() hs.grid.resizeWindowShorter(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "j", function() hs.grid.resizeWindowThinner(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "k", function() hs.grid.resizeWindowWider(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "l", function() hs.grid.resizeWindowTaller(hs.window.focusedWindow()) end)

hs.hotkey.bind({'cmd', 'alt', 'ctrl', 'shift'}, "h", function() hs.grid.pushWindowUp(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl', 'shift'}, "j", function() hs.grid.pushWindowLeft(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl', 'shift'}, "k", function() hs.grid.pushWindowRight(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl', 'shift'}, "l", function() hs.grid.pushWindowDown(hs.window.focusedWindow()) end)

-- Global on purpose, like configWatcher in init.lua: hs.eventtap does not
-- retain its own object and its __gc disables the tap, so a tap nothing points
-- at is collected and stops firing without a word.
mediaKeyTap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
    -- https://github.com/Hammerspoon/hammerspoon/issues/1220
    -- http://www.hammerspoon.org/docs/hs.eventtap.event.html#systemKey
    event = event:systemKey()
    -- http://stackoverflow.com/a/1252776/1521064
    local next = next
    -- Check empty table
    if next(event) then
        if event.key == 'PLAY' and event.down then
            -- Start Spotify if needed, but never steal focus from the
            -- current app when it is already running
            if hs.application.applicationsForBundleID(apps.spotify)[1] == nil then
                hs.application.open(apps.spotify)
            end

            hs.timer.doAfter(1, function ()
                local app = hs.application.applicationsForBundleID(apps.music)[1]
                if app ~= nil then
                    app:kill()
                end
            end)
        end
    end
end)
mediaKeyTap:start()

-- Vivaldi reload. `tell application id` rather than by name here too: it is the
-- same trap, AppleScript resolving a name through LaunchServices as well.
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "@", function()
  local script = string.format([[tell application id "%s" to tell the active tab of its first window
    reload
end tell]], apps.vivaldi)
  hs.osascript.applescript(script)
end)

-- Ghostty's quick terminal, which its own `global:` keybind cannot deliver
-- here: Ghostty and Hyperkey both install a *session* event tap, head-inserted,
-- so the last one registered is served first. Hyperkey starts with the session
-- and Ghostty relaunches after it -- on every update -- so Ghostty reads the
-- keyDown before Hyperkey has rewritten its flags, and matches a bare `m` with
-- no modifier at all. Measured both ways: the tap is up (`global event tap
-- enabled` in the log, so the Accessibility grant is fine) and an event
-- carrying real ctrl+alt+cmd injected at HID level, upstream of both taps, is
-- handled. A Carbon hotkey sits past the whole chain, where the flags are
-- there, which is what makes every other hyper binding in this file work.
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "m", function()
    -- Asked before the AppleScript on purpose: `tell application` launches what
    -- it addresses, and would block Hammerspoon's main loop for the whole
    -- launch. By id rather than by name, same trap as the Vivaldi reload above.
    if hs.application.applicationsForBundleID(apps.ghostty)[1] == nil then
        hs.application.open(apps.ghostty)
        return
    end

    -- `on` is not optional in Ghostty.sdef, so the action needs a terminal to
    -- dispatch through -- any one of them, the quick terminal is toggled at the
    -- application level. An application left with no window has none, and only
    -- the application itself can make one, hence the reopen event.
    local script = string.format([[tell application id "%s"
    if (count of windows) is 0 then return false
    return perform action "toggle_quick_terminal" on terminal 1 of window 1
end tell]], apps.ghostty)

    local ok, result = hs.osascript.applescript(script)
    if ok and result == false then
        hs.application.open(apps.ghostty)
    end
end)
