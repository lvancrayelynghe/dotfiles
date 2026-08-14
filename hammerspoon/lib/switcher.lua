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


local theWindows = hs.window.filter.new()
theWindows:setDefaultFilter{}
theWindows:setSortOrder(hs.window.filter.sortByFocusedLast)

-- Start by saving all windows, most recently focused first
obj.currentWindows = theWindows:getWindows()


-- the hammerspoon tracking of windows seems to be broken
-- we do it ourselves

local function callback_window_created(w, appName, event)

   if event == "windowDestroyed" then
      for i,v in ipairs(obj.currentWindows) do
         if v == w then
            table.remove(obj.currentWindows, i)
            return
         end
      end
      return -- not found: the rebuild below drops it anyway
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
-- over the accessibility API, which makes this the one real cost of a switch --
-- the reason nothing else on that path builds a title or an icon.
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

-- Windows worth switching to, most recently focused first, current one excluded.
-- The optional windows argument lets a caller reuse a list it already holds
-- rather than pay for a second accessibility sweep.
local function candidate_windows(onlyCurrentApp, windows)
   local currentWin = hs.window.focusedWindow() -- may be nil (desktop focused)
   local currentApp = currentWin and currentWin:application()
   local candidates = {}
   for _,w in ipairs(windows or refresh_current_windows()) do
      if w ~= currentWin and ((not onlyCurrentApp) or w:application() == currentApp) then
         table.insert(candidates, w)
      end
   end
   return candidates
end

-- Icons are read from the application bundle on disk, so they are kept; false
-- marks a bundle whose icon could not be read, so it is not asked for twice.
local appIcons = {}
local function app_icon(app)
   local bundleID = app and app:bundleID() -- nil for a bundle-less application,
   if not bundleID then return nil end     -- which imageFromAppBundle rejects
   if appIcons[bundleID] == nil then
      appIcons[bundleID] = hs.image.imageFromAppBundle(bundleID) or false
   end
   return appIcons[bundleID] or nil
end

-- Rows for the chooser, and for the chooser only: switchWindow() and
-- previousWindow() focus a single window and would throw away every title and
-- icon built here.
function obj:list_window_choices(onlyCurrentApp)
   local windowChoices = {}
   for i,w in ipairs(candidate_windows(onlyCurrentApp)) do
      local app = w:application()
      local appName = app and app:name() or '(none)'
      table.insert(windowChoices, {
                      text = (w:title() or '') .. "--" .. appName,
                      subText = appName,
                      uuid = i,
                      image = app_icon(app),
                      win = w})
   end
   return windowChoices;
end

-- focus() is not enough to bring a window forward. It makes the window main and
-- brings its application to the front, which leaves a minimized window
-- minimized -- the application comes forward and shows another of its windows
-- instead, so the switch looks like it did nothing -- and does just as little
-- for a window whose application is hidden. Undo both first; the window then
-- appears, and takes the focus, once the un-minimize animation is over.
local function reveal(w)
   local app = w:application()
   if app and app:isHidden() then app:unhide() end
   if w:isMinimized() then w:unminimize() end
   w:focus()
end

local windowChooser = hs.chooser.new(function(choice)
      if not choice then hs.alert.show("Nothing to focus"); return end
      local v = choice["win"]
      if v then
         reveal(v)
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


-- Focus the candidate at the given position, 1 being the most recently focused.
-- fallbackToAll: when the current application has no other window, fall back to
-- every application -- and, as before, to position 1 there rather than to the
-- requested one, the most recently focused window being the useful answer then.
-- Both passes share one window list, so the fallback costs no second sweep.
local function focusCandidate(onlyCurrentApp, index, fallbackToAll)
   local windows = refresh_current_windows()
   local candidates = candidate_windows(onlyCurrentApp, windows)
   if #candidates == 0 and onlyCurrentApp and fallbackToAll then
      candidates, index = candidate_windows(false, windows), 1
   end
   if #candidates == 0 then
      hs.alert.show("no other window available ")
      return
   end
   local w = candidates[(index == -1) and #candidates or index]
   if w then
      reveal(w)
   end
end

function obj:switchWindow(onlyCurrentApp)
   focusCandidate(onlyCurrentApp, -1, true) -- least recently focused window
end

function obj:previousWindow(onlyCurrentApp)
   focusCandidate(onlyCurrentApp, 1, false) -- most recently focused window
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
