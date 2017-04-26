-- API Doc : http://www.hammerspoon.org/docs/
-- KeyCodes : http://www.hammerspoon.org/docs/hs.keycodes.html#map

hs.hotkey.bind({"ctrl"}, "t",        function() hs.application.launchOrFocus("iTerm") end)
hs.hotkey.bind({"ctrl"}, "g",        function() hs.application.launchOrFocus("Google Chrome") end)
hs.hotkey.bind({"ctrl"}, "s",        function() hs.application.launchOrFocus("Sublime Text") end)
hs.hotkey.bind({"ctrl"}, "e",        function() hs.application.launchOrFocus("Finder") end)
hs.hotkey.bind({"ctrl"}, "v",        function() hs.application.launchOrFocus("Filezilla") end)
hs.hotkey.bind({"ctrl"}, "q",        function() hs.application.launchOrFocus("Calendar") end)
hs.hotkey.bind({"ctrl"}, "a",        function() hs.application.launchOrFocus("Slack") end)
hs.hotkey.bind({"ctrl"}, "m",        function() hs.application.launchOrFocus("Mail") end)
hs.hotkey.bind({"ctrl"}, "b",        function() hs.application.launchOrFocus("Sequel Pro") end)
hs.hotkey.bind({"ctrl"}, "l",        function() hs.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend") end)
hs.hotkey.bind({"ctrl"}, "p",        function() hs.execute("/usr/local/bin/subl /Users/lucvancrayelynghe/TODO.md") end)

-- Toggle Fullscreen
hs.hotkey.bind({"ctrl"}, "f", function()
  local win = hs.window.focusedWindow()
  win:toggleFullScreen()
end)

-- Close active window
hs.hotkey.bind({"ctrl"}, "x", function()
  local win = hs.window.focusedWindow()
  win:application():kill()
end)

-- Chrome reload
hs.hotkey.bind({"ctrl"}, "i", function()
  local script = [[tell application "Chrome" to tell the active tab of its first window
    reload
end tell]]
  hs.osascript.applescript(script)
end)

-- Caffeinate
local caffeine = hs.menubar.new()
function setCaffeineDisplay(state)
    if state then
        caffeine:setIcon(os.getenv("HOME") .. "/.hammerspoon/assets/caffeine-on.pdf")
    else
        caffeine:setIcon(os.getenv("HOME") .. "/.hammerspoon/assets/caffeine-off.pdf")
    end
end

function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
    caffeine:setClickCallback(caffeineClicked)
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

-- Autoconfig reload
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
        hs.notify.new({title="Hammerspoon", informativeText="Config reloaded !"}):send()
    end
end
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
