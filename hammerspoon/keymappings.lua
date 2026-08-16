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

    if hs.application.frontmostApplication():bundleID() == bundleID then
        switcher:switchWindow(true)
        return
    end

    -- unhide first: activate() never unhides (application.lua:71-79). On a
    -- hidden app it takes the focusedWindow branch and brings to the front
    -- windows that are still hidden, so the unhide that followed made them
    -- appear without the app being frontmost.
    app:unhide()
    app:activate(true)
end

-- App Bindings
for key, bundleID in pairs({
    ["a"] = apps.slack,
    ["e"] = apps.finder,

    ["s"] = apps.sublime,
    ["g"] = apps.vivaldi,

    ["z"] = apps.discord,
    ["r"] = apps.bruno,
    ["t"] = apps.ghostty,

    ["y"] = apps.harvest,

    ["p"] = apps.notes,
    ["q"] = apps.calendar,
    ["v"] = apps.vscode,
    ["c"] = apps.claude,

    ["f"] = apps.filezilla,

    ["x"] = apps.clickup,
    ["b"] = apps.sequelace,
}) do
    hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, key, function()
        launchOrSwitch(bundleID)
    end)
end


-- select any other window
-- hs.hotkey.bind({"alt"}, "b", function()
--     switcher:selectWindow(false)
-- end)

-- select any window for the same application
-- hs.hotkey.bind({"alt", "shift"}, "b", function()
--     switcher:selectWindow(true)
-- end)

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


-- hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "m", function() hs.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend") end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "o", function() hs.execute("/opt/homebrew/bin/subl ~/Library/Mobile\\ Documents/com~apple~CloudDocs/todo.md") end)

hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "h", function() hs.grid.resizeWindowShorter(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "j", function() hs.grid.resizeWindowThinner(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "k", function() hs.grid.resizeWindowWider(hs.window.focusedWindow()) end)
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "l", function() hs.grid.resizeWindowTaller(hs.window.focusedWindow()) end)

hs.hotkey.bind({"ctrl", "cmd"}, "h", function() hs.grid.pushWindowUp(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl", "cmd"}, "j", function() hs.grid.pushWindowLeft(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl", "cmd"}, "k", function() hs.grid.pushWindowRight(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl", "cmd"}, "l", function() hs.grid.pushWindowDown(hs.window.focusedWindow()) end)

-- Toggle Fullscreen
-- hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "f", function()
--   local win = hs.window.focusedWindow()
--   win:toggleFullScreen()
-- end)

-- Close active window
-- hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "x", function()
--   local win = hs.window.focusedWindow()
--   win:application():kill()
-- end)

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
