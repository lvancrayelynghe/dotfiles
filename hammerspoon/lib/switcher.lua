--- Source : https://github.com/Porco-Rosso/PorcoSpoon

--- Modified version of dmg hammerspoon
--- credit to the original author below

local obj={}
obj.__index = obj

-- metadata
obj.name = "selectWindow"
obj.author = "dmg <dmg@turingmachine.org>"
obj.homepage = "https://github.com/dmgerman/hs_select_window.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- things to configure

obj.rowsToDisplay = 14 -- how many rows to display in the chooser


-- -- for debugging purposes
-- function obj:print_table(t, f)
--    for i,v in ipairs(t) do
--       print(i, f(v))
--    end
-- end
--
-- -- for debugging purposes
--
-- function obj:print_windows()
--    function w_info(w)
--       return w:title() .. w:application():name()
--    end
--    obj:print_table(hs.window.visibleWindows(), w_info)
-- end

local theWindows = hs.window.filter.new()
theWindows:setDefaultFilter{}
theWindows:setSortOrder(hs.window.filter.sortByFocusedLast)
obj.currentWindows = {}
obj.previousSelection = nil  -- the idea is that one switches back and forth between two windows all the time


-- Start by saving all windows

for i,v in ipairs(theWindows:getWindows()) do
   table.insert(obj.currentWindows, v)
end

function obj:find_window_by_title(t)
   -- find a window by title.
   for i,v in ipairs(obj.currentWindows) do
      if string.find(v:title(), t) then
         return v
      end
   end
   return nil
end

function obj:focus_by_title(t)
   -- focus the window with given title
   if not t then
      hs.alert.show("No string provided to focus_by_title")
      return nil
   end
   local w = obj:find_window_by_title(t)
   if w then
      w:focus()
   end
   return w
end

function obj:focus_by_app(appName)
   -- find a window with that application name and jump to it
--   print(' [' .. appName ..']')
   for i,v in ipairs(obj.currentWindows) do
--      print('           [' .. v:application():name() .. ']')
      if string.find(v:application():name(), appName) then
--         print("Focusing window" .. v:title())
         v:focus()
         return v
      end
   end
   return nil
end


-- the hammerspoon tracking of windows seems to be broken
-- we do it ourselves

local function callback_window_created(w, appName, event)

   if event == "windowDestroyed" then
--      print("deleting from windows-----------------", w)
      if w then
--         print("destroying window" .. w:title())
      end
      for i,v in ipairs(obj.currentWindows) do
         if v == w then
            table.remove(obj.currentWindows, i)
            return
         end
      end
--      print("Not found .................. ", w)
--      obj:print_table0(obj.currentWindows)
--      print("Not found ............ :()", w)
      return
   end
   if event == "windowCreated" then
      if not w then return end
      -- A brand new window is not necessarily focused yet, and a windowFocused
      -- event follows when it is; a window the filter registers late -- see the
      -- wake watcher at the bottom -- never is, and must not jump the queue.
      local focused = hs.window.focusedWindow()
      if focused and w:id() == focused:id() then
         table.insert(obj.currentWindows, 1, w)
      else
         table.insert(obj.currentWindows, w)
      end
      return
   end
   if event == "windowFocused" then
      -- equivalent to a delete followed by an insert at the most recent end
      callback_window_created(w, appName, "windowDestroyed")
      if w then
         table.insert(obj.currentWindows, 1, w)
      end
   end
end
theWindows:subscribe(hs.window.filter.windowCreated, callback_window_created)
theWindows:subscribe(hs.window.filter.windowDestroyed, callback_window_created)
theWindows:subscribe(hs.window.filter.windowFocused, callback_window_created)


-- The list above is fed by events only, so it misses any window the filter
-- failed to register -- it then reports no event at all for it, which is what
-- the "wfilter: ... is STILL not registered" warnings in the console mean.
-- Rebuild the list before every lookup: windows that are gone and duplicates
-- are dropped, and the visible windows the filter does not know about are
-- appended front to back at the least recently focused end, since we have no
-- focus history for them. hs.window.orderedWindows() queries every application
-- over the accessibility API, i.e. the same order of cost as the titles and
-- icons collected below.
--
-- The role check is how the filter's own rules are kept: setDefaultFilter{}
-- overrides no role, so allowedWindowRoles is the effective rule and popovers
-- or sheets stay out. Its isWindowAllowed() is of no use here -- on a
-- subscribed filter it only answers "is this window in my tracked set?", which
-- is the very bookkeeping this function exists to bypass, and it answers it
-- wrongly at that: window_filter.lua:280 indexes a Window-keyed table with a
-- window id, so it returns false for every window.
local function refresh_current_windows()
   local windows, seen = {}, {}
   for _,w in ipairs(obj.currentWindows) do
      local id = w:id() -- nil once the window is gone
      if id and not seen[id] then
         seen[id] = true
         table.insert(windows, w)
      end
   end
   for _,w in ipairs(hs.window.orderedWindows()) do
      local id = w:id()
      if id and not seen[id] and hs.window.filter.allowedWindowRoles[w:subrole()] then
         seen[id] = true
         table.insert(windows, w)
      end
   end
   obj.currentWindows = windows
   return windows
end

function obj:list_window_choices(onlyCurrentApp)
   local windowChoices = {}
   local currentWin = hs.window.focusedWindow() -- may be nil (desktop focused)
   local currentApp = currentWin and currentWin:application()
   -- print("\nstarting to populate")
   -- print(currentApp)
   for i,w in ipairs(refresh_current_windows()) do
      if w ~= currentWin then
         local app = w:application()
         local appImage = nil
         local appName  = '(none)'
         if app then
            appName = app:name()
            appImage = hs.image.imageFromAppBundle(w:application():bundleID())
         end
         -- print(appName, currentApp)
         if (not onlyCurrentApp) or (app == currentApp) then
            -- print("inserting...")
            table.insert(windowChoices, {
                            text = (w:title() or '') .. "--" .. appName,
                            subText = appName,
                            uuid = i,
                            image = appImage,
                            win=w})
         end
      end
   end
   return windowChoices;
end

local windowChooser = hs.chooser.new(function(choice)
      if not choice then hs.alert.show("Nothing to focus"); return end
      local v = choice["win"]
      if v then
         v:focus()
      else
         hs.alert.show("unable to focus " .. (choice["text"] or "window"))
      end
end)

function obj:selectWindow(onlyCurrentApp)
   local windowChoices = obj:list_window_choices(onlyCurrentApp)
   if #windowChoices == 0 then
      if onlyCurrentApp then
         obj:previousWindow(false)
      else
         hs.alert.show("no other window available ")
      end
      return
   end
   windowChooser:choices(windowChoices)
   --windowChooser:placeholderText('')
   windowChooser:rows(obj.rowsToDisplay)
   windowChooser:query(nil)
   windowChooser:show()
end


-- Focus the window at the given position in the choices list.
-- fallbackToAll: retry across all applications when the current app has no other window.
local function focusChoice(onlyCurrentApp, index, fallbackToAll)
   local windowChoices = obj:list_window_choices(onlyCurrentApp)
   if #windowChoices == 0 then
      if onlyCurrentApp and fallbackToAll then
         focusChoice(false, 1, false)
      else
         hs.alert.show("no other window available ")
      end
      return
   end
   local i = (index == -1) and #windowChoices or index
   local v = windowChoices[i]["win"]
   if v then
      v:focus()
   end
end

function obj:switchWindow(onlyCurrentApp)
   focusChoice(onlyCurrentApp, -1, true) -- least recently focused window
end

function obj:previousWindow(onlyCurrentApp)
   focusChoice(onlyCurrentApp, 1, false) -- most recently focused window
end


-- hs.window.filter loses a window for good whenever the accessibility API is
-- momentarily incoherent, which is exactly what a wake looks like: the focused
-- window of an application fails to register, the filter logs "... is STILL not
-- registered", and from then on it reports no event for that window at all.
-- switchedToSpace() makes every filter re-enumerate the windows of every
-- running application; -1 is the one space number it does not memoise, so
-- unlike a real space number it forces that refresh on each call.
local function refresh_window_filter()
   hs.window.filter.switchedToSpace(-1)
end

-- Long-lived on purpose: an hs.timer.delayed cannot be removed from the run
-- loop, so both are created once, here. Two passes because the accessibility
-- API can still be unreliable seconds after a wake; the second one is a no-op
-- when the first was enough.
local filterRefreshSoon = hs.timer.delayed.new(3, refresh_window_filter)
local filterRefreshLate = hs.timer.delayed.new(15, refresh_window_filter)

-- Kept on the module table: a local watcher would be garbage-collected.
obj.wakeWatcher = hs.caffeinate.watcher.new(function(event)
   if event == hs.caffeinate.watcher.systemDidWake
      or event == hs.caffeinate.watcher.screensDidUnlock then
      filterRefreshSoon:start()
      filterRefreshLate:start()
   end
end):start()

-- A Space change needs the same refresh, and hs.window.filter does run one on
-- its own -- its internal hs.spaces.watcher goes through the very same -1 --
-- but it runs it the instant the notification arrives, while the transition,
-- and the accessibility state that goes with it, is still settling. Hence one
-- more pass once things have quietened down.
local filterRefreshAfterSpace = hs.timer.delayed.new(1, refresh_window_filter)

obj.spacesWatcher = hs.spaces.watcher.new(function()
   filterRefreshAfterSpace:start()
end):start()

return obj
