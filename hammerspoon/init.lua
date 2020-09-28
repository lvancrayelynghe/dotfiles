-- API Doc : http://www.hammerspoon.org/docs/
-- KeyCodes : http://www.hammerspoon.org/docs/hs.keycodes.html#map

-- Force launch or focus an app by name (fix issues with Finder)
-- @see https://github.com/cmsj/hammerspoon-config/blob/master/init.lua#L156
-- @see http://liuhao.im/english/2017/06/02/macos-automation-and-shortcuts-with-hammerspoon.html
function launchOrFocusOrHide(appname)
    local app = hs.appfinder.appFromName(appname)
    if not app then
        if appname == "Calendrier" then
            hs.application.launchOrFocus("Calendar")
        else
            hs.application.launchOrFocus(appname)
        end
        return
    end

    if appname == "Finder" then
        app:activate(true)
        app:unhide()
        return
    end

    local mainwin = app:mainWindow()
    if mainwin then
        if mainwin == hs.window.focusedWindow() then
            app:hide()
        else
            app:activate(true)
            app:unhide()
            mainwin:focus()
        end
    else
        if appname == "Calendrier" then
            app:activate(true)
            app:unhide()
            app:selectMenuItem({'Fenêtre', 'Calendrier'})
            app:mainWindow():focus()
            return
        end
    end
end

-- Set a screen grid size
hs.grid.setGrid('12x12')
hs.grid.setMargins('0x0')

-- Key bindings
hs.hotkey.bind({"ctrl"}, "t", function() launchOrFocusOrHide("iTerm") end)
hs.hotkey.bind({"ctrl"}, "g", function() launchOrFocusOrHide("Google Chrome") end)
hs.hotkey.bind({"ctrl"}, "s", function() launchOrFocusOrHide("Sublime Text") end)
hs.hotkey.bind({"ctrl"}, "v", function() launchOrFocusOrHide("Visual Studio Code") end)
hs.hotkey.bind({"ctrl"}, "e", function() launchOrFocusOrHide("Finder") end)
hs.hotkey.bind({"ctrl"}, "f", function() launchOrFocusOrHide("Filezilla") end)
hs.hotkey.bind({"ctrl"}, "q", function() launchOrFocusOrHide("Calendrier") end)
hs.hotkey.bind({"ctrl"}, "a", function() launchOrFocusOrHide("Slack") end)
hs.hotkey.bind({"ctrl"}, "b", function() launchOrFocusOrHide("Sequel Ace") end)
hs.hotkey.bind({"ctrl"}, "z", function() launchOrFocusOrHide("Discord") end)
hs.hotkey.bind({"ctrl"}, "r", function() launchOrFocusOrHide("Postman") end)
hs.hotkey.bind({"ctrl"}, "m", function() hs.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend") end)
-- hs.hotkey.bind({"ctrl"}, "p", function() hs.execute("/usr/local/bin/subl /Users/lucvancrayelynghe/TODO.md") end)
-- hs.hotkey.bind({"ctrl"}, "m", function() launchOrFocusOrHide("Mail") end)

hs.hotkey.bind({"ctrl"}, "h", function() hs.grid.resizeWindowShorter(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl"}, "j", function() hs.grid.resizeWindowThinner(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl"}, "k", function() hs.grid.resizeWindowWider(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl"}, "l", function() hs.grid.resizeWindowTaller(hs.window.focusedWindow()) end)

hs.hotkey.bind({"ctrl", "cmd"}, "h", function() hs.grid.pushWindowUp(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl", "cmd"}, "j", function() hs.grid.pushWindowLeft(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl", "cmd"}, "k", function() hs.grid.pushWindowRight(hs.window.focusedWindow()) end)
hs.hotkey.bind({"ctrl", "cmd"}, "l", function() hs.grid.pushWindowDown(hs.window.focusedWindow()) end)

-- Toggle Fullscreen
-- hs.hotkey.bind({"ctrl"}, "f", function()
--   local win = hs.window.focusedWindow()
--   win:toggleFullScreen()
-- end)

-- Close active window
-- hs.hotkey.bind({"ctrl"}, "x", function()
--   local win = hs.window.focusedWindow()
--   win:application():kill()
-- end)

-- Chrome reload
hs.hotkey.bind({"ctrl"}, "u", function()
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
