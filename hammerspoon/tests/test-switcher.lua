-- Tests for lib/switcher.lua, run outside Hammerspoon:
--
--     lua hammerspoon/tests/test-switcher.lua
--
-- The module is loaded against a stub of the hs API, which is the only way to
-- exercise it at all: there is no hs CLI and AppleScript is off, so nothing can
-- drive the live config from a terminal. The stubs answer just enough for the
-- window-list bookkeeping, and count the expensive calls (the accessibility
-- sweep, the icon loading) so the cheap paths stay cheap.
--
-- This file is symlinked into ~/.hammerspoon/tests/ along with the rest of the
-- directory, where nothing loads it -- Hammerspoon only reads init.lua. Saving
-- it does reload the live config all the same, through the pathwatcher.

local sweeps, images, appSweeps = 0, 0, 0
local subscribed, watchers, focusCalls, alerts, actions = {}, {}, {}, {}, {}
local focused, orderedWindows, noBundle, hidden = nil, {}, {}, {}
-- what each application answers to allWindows(), by application name
local windowsOfApp = {}

-- One shared table per application name, so that `app == currentApp` holds the
-- way it does for hs.application userdata.
local apps = setmetatable({}, {__index = function(t, name)
    local app = {
        name = function() return name end,
        isHidden = function() return hidden[name] == true end,
        unhide = function()
            hidden[name] = false
            table.insert(actions, 'unhide:' .. name)
        end,
        bundleID = function()
            if noBundle[name] then return nil end
            return 'id.' .. name
        end,
        -- one application queried, not the whole accessibility sweep
        allWindows = function()
            appSweeps = appSweeps + 1
            return windowsOfApp[name] or {}
        end,
        activate = function(_, allWindows)
            table.insert(actions, 'activate:' .. name .. ':' .. tostring(allWindows))
            return true
        end,
    }
    t[name] = app
    return app
end})

local function W(id, title, appname, subrole)
    local w = {alive = true, minimized = false, _id = id, _title = title,
               _app = appname, _subrole = subrole or 'AXStandardWindow'}
    function w:id() if self.alive then return self._id end return nil end
    function w:title() return self._title end
    function w:subrole() return self._subrole end
    function w:application() return apps[self._app] end
    function w:isMinimized() return self.minimized end
    function w:unminimize()
        self.minimized = false
        table.insert(actions, 'unminimize:' .. self._id)
    end
    function w:focus()
        table.insert(focusCalls, self._id)
        table.insert(actions, 'focus:' .. self._id)
    end
    return w
end

hs = {
    window = {
        focusedWindow = function() return focused end,
        orderedWindows = function() sweeps = sweeps + 1 return orderedWindows end,
        filter = {
            windowCreated = 'windowCreated',
            windowDestroyed = 'windowDestroyed',
            windowFocused = 'windowFocused',
            sortByFocusedLast = 'sortByFocusedLast',
            -- same default as hs.window.filter.allowedWindowRoles
            allowedWindowRoles = {AXStandardWindow = true, AXDialog = true,
                                  AXSystemDialog = true},
            switchedToSpace = function(n)
                table.insert(watchers, 'switchedToSpace:' .. n)
            end,
            new = function()
                local f = {}
                function f:setDefaultFilter() end
                function f:setSortOrder() end
                function f:subscribe(event, fn) subscribed[event] = fn end
                function f:getWindows() return {} end
                return f
            end,
        },
    },
    image = {
        imageFromAppBundle = function(bundleID)
            images = images + 1
            -- the real one is declared LS_TSTRING and raises on anything else
            assert(type(bundleID) == 'string', 'imageFromAppBundle needs a string')
            return 'image:' .. bundleID
        end,
    },
    chooser = {
        new = function()
            return {choices = function() end, rows = function() end,
                    query = function() end, show = function() end}
        end,
    },
    alert = {show = function(message) table.insert(alerts, message) end},
    timer = {
        delayed = {
            new = function(delay, fn)
                local t = {delay = delay, fn = fn}
                -- fired inline: the callback order is what is under test
                function t:start()
                    table.insert(watchers, 'refresh@' .. self.delay)
                    self.fn()
                end
                table.insert(watchers, 'timer@' .. delay)
                return t
            end,
        },
    },
    caffeinate = {
        watcher = {
            systemDidWake = 'systemDidWake',
            screensDidUnlock = 'screensDidUnlock',
            new = function(fn)
                local w = {fn = fn}
                function w:start()
                    table.insert(watchers, 'wakeWatcher started')
                    return self
                end
                return w
            end,
        },
    },
    spaces = {
        watcher = {
            new = function(fn)
                local w = {fn = fn}
                function w:start()
                    table.insert(watchers, 'spacesWatcher started')
                    return self
                end
                return w
            end,
        },
    },
}

local here = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or './'
local switcher = dofile(here .. '../lib/switcher.lua')

local failed = 0
local function check(label, got, want)
    if got == want then
        print(string.format('ok    %-50s %s', label, tostring(got)))
    else
        print(string.format('FAIL  %-50s got %s, want %s',
                            label, tostring(got), tostring(want)))
        failed = failed + 1
    end
end

-- ids of the windows carried by a list of chooser rows
local function rowIds(rows)
    local r = {}
    for _, row in ipairs(rows) do table.insert(r, row.win:id()) end
    return table.concat(r, ',')
end

-- ids of the windows the module currently tracks, most recently focused first
local function trackedIds()
    local r = {}
    for _, w in ipairs(switcher.currentWindows) do
        table.insert(r, tostring(w:id()))
    end
    return table.concat(r, ',')
end

local A = W(1, 'A win', 'Vivaldi')
local B = W(2, 'B win', 'Sublime Text')
local C = W(3, 'C win', 'Vivaldi')


-- Wiring ---------------------------------------------------------------------

local emit = subscribed.windowCreated
check('the three events share one callback',
      subscribed.windowDestroyed == emit and subscribed.windowFocused == emit, true)
check('watchers and timers set up at load', table.concat(watchers, ' '),
      'timer@3 timer@15 wakeWatcher started timer@1 spacesWatcher started')


-- Rebuilding the list --------------------------------------------------------

-- a window the filter never registered is picked up, at the least recent end
switcher.currentWindows = {A, B}
orderedWindows = {C, A, B} -- front to back; C is the one the filter missed
focused = A
check('unregistered window appended at the tail',
      rowIds(switcher:list_window_choices(false)), '2,3')
check('tracked list rebuilt', trackedIds(), '1,2,3')

-- a window that is gone drops out: its id() no longer answers
switcher.currentWindows = {A, B, C}
orderedWindows = {A, C}
B.alive = false
check('window that is gone dropped', rowIds(switcher:list_window_choices(false)), '3')
B.alive = true

-- duplicates, which a missed windowDestroyed leaves behind, are collapsed
switcher.currentWindows = {A, B, A, B}
orderedWindows = {A, B}
switcher:list_window_choices(false)
check('duplicates collapsed', trackedIds(), '1,2')

-- the filter's own role rule is kept, since isWindowAllowed() cannot be used
switcher.currentWindows = {A}
orderedWindows = {A, W(9, 'a popover', 'Vivaldi', 'AXUnknown')}
check('window with a rejected role stays out',
      rowIds(switcher:list_window_choices(false)), '')
switcher.currentWindows = {A}
orderedWindows = {A, W(10, 'a dialog', 'Vivaldi', 'AXDialog')}
check('dialog role is appended', rowIds(switcher:list_window_choices(false)), '10')


-- Event bookkeeping ----------------------------------------------------------

-- a new window that is not focused yet must not pass for the last one used
switcher.currentWindows = {A, B}
focused = A
emit(C, 'Vivaldi', 'windowCreated')
check('unfocused new window goes to the tail', trackedIds(), '1,2,3')

switcher.currentWindows = {A, B}
focused = C
emit(C, 'Vivaldi', 'windowCreated')
check('focused new window goes to the head', trackedIds(), '3,1,2')

switcher.currentWindows = {A, B, C}
focused = C
emit(C, 'Vivaldi', 'windowFocused')
check('windowFocused moves to the head', trackedIds(), '3,1,2')

switcher.currentWindows = {A, B, C}
emit(B, 'Sublime Text', 'windowDestroyed')
check('windowDestroyed removes the window', trackedIds(), '1,3')


-- Choosing a window ----------------------------------------------------------

switcher.currentWindows = {A, B, C}
orderedWindows = {A, B, C}
focused, focusCalls = A, {}
switcher:previousWindow(false)
check('previousWindow focuses the most recent other window', focusCalls[1], 2)

focusCalls = {}
switcher:switchWindow(false)
check('switchWindow focuses the least recent window', focusCalls[1], 3)

focused = A -- Vivaldi, like C
check('onlyCurrentApp keeps the same application',
      rowIds(switcher:list_window_choices(true)), '3')

-- the current application has no other window: fall back to every application,
-- and there to the most recently focused one -- with a single sweep
switcher.currentWindows = {A, C, B}
orderedWindows = {A, C, B}
focused, sweeps, focusCalls = B, 0, {}
switcher:switchWindow(true)
check('fallback focuses the most recent window overall', focusCalls[1], 1)
check('fallback sweeps once', sweeps, 1)

-- nothing to switch to at all
switcher.currentWindows = {A}
orderedWindows = {A}
focused, focusCalls, alerts = A, {}, {}
switcher:previousWindow(false)
check('no candidate focuses nothing', #focusCalls, 0)
check('no candidate warns', alerts[1], 'no other window available ')


-- Revealing the window ---------------------------------------------------------

-- focus() alone leaves a minimized window minimized -- the application merely
-- comes forward showing another of its windows -- so it must be un-minimized
switcher.currentWindows = {A, C}
orderedWindows = {A} -- a minimized window is not in orderedWindows either
focused, actions = A, {}
C.minimized = true
switcher:previousWindow(false)
check('minimized window un-minimized then focused',
      table.concat(actions, ' '), 'unminimize:3 focus:3')
check('minimized window kept in the list despite orderedWindows', trackedIds(), '1,3')

-- and a window of a hidden application needs the application unhidden first
switcher.currentWindows = {A, B}
orderedWindows = {A}
focused, actions = A, {}
hidden['Sublime Text'] = true
switcher:previousWindow(false)
check('hidden application unhidden then focused',
      table.concat(actions, ' '), 'unhide:Sublime Text focus:2')

-- an ordinary window needs neither
switcher.currentWindows = {A, B}
orderedWindows = {A, B}
focused, actions = A, {}
switcher:previousWindow(false)
check('ordinary window only focused', table.concat(actions, ' '), 'focus:2')


-- Reaching a whole application -----------------------------------------------

-- ids of a list of windows, in order
local function winIds(windows)
    local r = {}
    for _, w in ipairs(windows) do table.insert(r, tostring(w:id())) end
    return table.concat(r, ',')
end

local V = apps['Vivaldi']
local S = apps['Sublime Text']
local D = W(4, 'D win', 'Vivaldi') -- never registered by the filter

-- the tracked list carries the focus order, so it comes first; what only the
-- application knows about is appended
switcher.currentWindows = {A, B, C}
windowsOfApp['Vivaldi'] = {C, A, D}
appSweeps, sweeps = 0, 0
check('appWindows keeps the tracked focus order first',
      winIds(switcher:appWindows(V)), '1,3,4')
check('appWindows sweeps the one application', appSweeps, 1)
check('appWindows sweeps no other', sweeps, 0)

-- a minimized window is in neither orderedWindows nor the tracked list when the
-- filter missed it; app:allWindows() is the only place left it shows up
switcher.currentWindows = {}
orderedWindows = {}
B.minimized = true
windowsOfApp['Sublime Text'] = {B}
check('a minimized window the filter missed is still found',
      winIds(switcher:appWindows(S)), '2')
B.minimized = false

-- app:allWindows() hands out the Finder desktop as if it were a window
switcher.currentWindows = {A}
windowsOfApp['Finder'] = {W(0, '', 'Finder', '')} -- an AXScrollArea, no subrole
check('the Finder desktop is not a window to bring forward',
      #switcher:appWindows(apps['Finder']), 0)

-- an application closed with cmd-W: still running, nothing left to show
windowsOfApp['Calendrier'] = {}
check('an application closed to nothing has no window',
      #switcher:appWindows(apps['Calendrier']), 0)


-- activate() brings the application forward and stops there, so a window whose
-- application is up but minimized has to be revealed
switcher.currentWindows = {B}
windowsOfApp['Sublime Text'] = {B}
B.minimized = true
actions = {}
switcher:focusApp(S)
check('an application with only minimized windows is revealed',
      table.concat(actions, ' '), 'unminimize:2 focus:2 activate:Sublime Text:true')

-- with a window already on screen there is nothing to reveal
B.minimized = false
actions = {}
switcher:focusApp(S)
check('an application already showing a window is only activated',
      table.concat(actions, ' '), 'activate:Sublime Text:true')

-- and a window minimized behind a visible one stays where the user left it
local B2 = W(5, 'B other win', 'Sublime Text')
switcher.currentWindows = {B, B2} -- the minimized one is the most recent
windowsOfApp['Sublime Text'] = {B, B2}
B.minimized, actions = true, {}
switcher:focusApp(S)
check('a window minimized behind a visible one is left alone',
      table.concat(actions, ' '), 'activate:Sublime Text:true')
B.minimized = false

-- hidden is the other way an application shows nothing
switcher.currentWindows = {B}
windowsOfApp['Sublime Text'] = {B}
hidden['Sublime Text'], actions = true, {}
switcher:focusApp(S)
check('a hidden application is unhidden before it is activated',
      table.concat(actions, ' '), 'unhide:Sublime Text activate:Sublime Text:true')

-- hidden and minimized at once: reveal() undoes both, in that order
hidden['Sublime Text'], B.minimized, actions = true, true, {}
switcher:focusApp(S)
check('hidden and minimized are both undone', table.concat(actions, ' '),
      'unhide:Sublime Text unminimize:2 focus:2 activate:Sublime Text:true')
hidden['Sublime Text'], B.minimized = nil, false

-- the caller's list is reused rather than rebuilt
appSweeps, actions = 0, {}
switcher:focusApp(V, {A})
check('focusApp reuses the list it is handed', appSweeps, 0)
check('focusApp still activates', table.concat(actions, ' '), 'activate:Vivaldi:true')


-- Titles and icons, chooser only ---------------------------------------------

switcher.currentWindows = {A, B, C}
orderedWindows = {A, B, C}
focused, images, sweeps = A, 0, 0
switcher:previousWindow(false)
check('focus path builds no icon', images, 0)
check('focus path sweeps once', sweeps, 1)

-- two windows of one still-unseen application plus one of another:
-- three rows, two icons
local N1, N2 = W(20, 'note 1', 'Notes'), W(21, 'note 2', 'Notes')
local R = W(22, 'a request', 'Bruno')
switcher.currentWindows = {A, N1, N2, R}
orderedWindows = {A, N1, N2, R}
focused, images = A, 0
local rows = switcher:list_window_choices(false)
check('chooser rows carry an icon', rows[1].image, 'image:id.Notes')
check('one row per candidate', #rows, 3)
check('icons built once per bundle id', images, 2)
images = 0
switcher:list_window_choices(false)
check('icons served from the cache afterwards', images, 0)

check('row text is title then application name', rows[1].text, 'note 1--Notes')
local U = W(23, nil, 'Ghostty') -- an untitled window must not break the chooser
switcher.currentWindows = {A, U}
orderedWindows = {A, U}
rows = switcher:list_window_choices(false)
check('nil title tolerated', rows[1].text, '--Ghostty')

noBundle['Ghostty'] = true
rows = switcher:list_window_choices(false)
check('bundle-less application yields no icon', tostring(rows[1].image), 'nil')
check('bundle-less application still listed', rowIds(rows), '23')
noBundle['Ghostty'] = nil


-- Refreshing the window filter -----------------------------------------------

watchers = {}
switcher.wakeWatcher.fn('systemDidWake')
check('wake triggers both refreshes', table.concat(watchers, ' '),
      'refresh@3 switchedToSpace:-1 refresh@15 switchedToSpace:-1')

watchers = {}
switcher.wakeWatcher.fn('someOtherPowerEvent')
check('unrelated power event does nothing', #watchers, 0)

watchers = {}
switcher.spacesWatcher.fn(3)
check('space change triggers one refresh', table.concat(watchers, ' '),
      'refresh@1 switchedToSpace:-1')


print(failed == 0 and '\nALL PASS' or ('\n' .. failed .. ' FAILURE(S)'))
os.exit(failed == 0 and 0 or 1)
