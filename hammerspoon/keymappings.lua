-- KeyCodes : http://www.hammerspoon.org/docs/hs.keycodes.html#map

function lanchOrSwitch(appname)
    local app = hs.appfinder.appFromName(appname)

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
    ["z"] = "Discord",
    ["e"] = "Finder",
    ["r"] = "Bruno",
    ["t"] = "iTerm",
    ["y"] = "Harvest",

    ["p"] = "FSNotes",

    ["q"] = "Calendrier",
    ["s"] = "Sublime Text",
    ["f"] = "Filezilla",
    ["g"] = "Google Chrome",

    ["x"] = "ClickUp",
    ["v"] = "Code",
    ["b"] = "Sequel Ace",
}) do
    hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, key, function()
        lanchOrSwitch(app)
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
-- hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "p", function() hs.execute("/usr/local/bin/subl /Users/lucvancrayelynghe/TODO.md") end)

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
            launch("Spotify")

            hs.timer.doAfter(1, function ()
                local app = hs.appfinder.appFromName('Musique')
                if app ~= nil then
                    app:kill()
                end
            end)
        end
    end
end):start()

-- Chrome reload
hs.hotkey.bind({'cmd', 'alt', 'ctrl'}, "@", function()
  local script = [[tell application "Chrome" to tell the active tab of its first window
    reload
end tell]]
  hs.osascript.applescript(script)
end)
