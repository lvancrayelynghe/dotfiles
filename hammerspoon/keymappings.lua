-- KeyCodes : http://www.hammerspoon.org/docs/hs.keycodes.html#map

-- find(name, true) rather than a loose name search: hs.application.get() -- and
-- hs.appfinder.appFromName(), which is a plain alias of it -- matches on
-- substrings, so "Code" also finds Xcode, and when nothing matches it falls
-- back to searching every window title, which readily returns the browser
-- holding a tab with that name in it. With exact = true neither happens.
function launchOrSwitch(appname)
    local app = hs.application.find(appname, true)

    if app == nil then
        hs.application.open(appname)
        return
    end

    if hs.application.frontmostApplication():name() == appname then
        switcher:switchWindow(true)
        return
    end

    app:activate(true)
    app:unhide()
end

-- App Bindings
for key, app in pairs({
    ["a"] = "Slack",
    ["e"] = "Finder",

    ["s"] = "Sublime Text",
    ["g"] = "Vivaldi",

    -- ["z"] = "Discord",
    -- ["r"] = "Bruno",
    -- ["t"] = "iTerm",

    -- ["y"] = "Harvest",

    -- ["p"] = "Notes",
    -- ["q"] = "Calendrier",
    -- ["v"] = "Code",

    -- ["f"] = "Filezilla",

    -- ["x"] = "ClickUp",
    -- ["b"] = "Sequel Ace",
}) do
    hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, key, function()
        launchOrSwitch(app)
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

hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
    -- https://github.com/Hammerspoon/hammerspoon/issues/1220
    -- http://www.hammerspoon.org/docs/hs.eventtap.event.html#systemKey
    event = event:systemKey()
    -- http://stackoverflow.com/a/1252776/1521064
    local next = next
    -- Check empty table
    if next(event) then
        if event.key == 'PLAY' and event.down then
            -- Start Spotify if needed, but never steal focus from the
            -- current app when it is already running.
            -- By bundle id throughout: a name search matches on substrings and
            -- falls back to window titles, so 'Musique' -- the localised name,
            -- another reason not to search for it -- would return the browser
            -- holding a tab with that word in it, and kill() would quit *that*.
            if hs.application.applicationsForBundleID('com.spotify.client')[1] == nil then
                hs.application.open('com.spotify.client')
            end

            hs.timer.doAfter(1, function ()
                local app = hs.application.applicationsForBundleID('com.apple.Music')[1]
                if app ~= nil then
                    app:kill()
                end
            end)
        end
    end
end):start()

-- Vivaldi reload
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "@", function()
  local script = [[tell application "Vivaldi" to tell the active tab of its first window
    reload
end tell]]
  hs.osascript.applescript(script)
end)
