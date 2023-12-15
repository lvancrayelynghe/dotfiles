-- API Doc : http://www.hammerspoon.org/docs/

hs.application.enableSpotlightForNameSearches(true)

switcher  = require('lib/switcher')

require('caffeinate')
require('keymappings')
require('layouts')

-- Set a screen grid size
hs.grid.setGrid('12x12')
hs.grid.setMargins('0x0')

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
