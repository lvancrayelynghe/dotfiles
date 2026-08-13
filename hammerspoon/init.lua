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
local function reloadConfig(files)
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload() -- destroys the Lua state: nothing after this call runs
            return
        end
    end
end
-- Global on purpose: a local watcher would be garbage-collected and stop working
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
