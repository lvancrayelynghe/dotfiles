-- Tests for layouts.lua, run outside Hammerspoon:
--
--     lua hammerspoon/tests/test-layouts.lua
--
-- Nothing in that module is exported, so it is driven the way the user drives it:
-- the stub captures the function passed to menu:setMenu(), and the tests call the
-- items it returns. hs.layout.apply is recorded rather than performed, so the
-- assertions are about what the layout *asks* for -- which screen, which rect,
-- which window state -- without a window moving anywhere.

local calls, settings = {}, {}
local screens, running = {}, {}

local function reset()
    calls = {layout = {}, fullscreen = {}, unfullscreen = {}, minimized = {}, opened = {}}
end
reset()

-- Fake screen. Roles are worked out from the name and the shape, exactly as
-- layouts.lua does, so the fixtures mirror the real ones: 1800x1169 built-in,
-- 2560x1440 landscape, 1440x2560 portrait.
local function Screen(id, name, w, h)
    local s = {_id = id, _name = name, _w = w, _h = h}
    function s:id() return self._id end
    function s:name() return self._name end
    function s:getUUID() return 'uuid-' .. self._id end
    function s:fullFrame() return {x = 0, y = 0, w = self._w, h = self._h} end
    function s:frame() return {x = 0, y = 0, w = self._w, h = self._h} end
    return s
end

local BUILTIN = Screen(1, 'Built-in Retina Display', 1800, 1169)
local LANDSCAPE = Screen(2, 'LG HDR 4K (1)', 2560, 1440)
local PORTRAIT = Screen(3, 'LG HDR 4K (2)', 1440, 2560)

local function Window(id, screen, opts)
    opts = opts or {}
    local w = {_id = id, _screen = screen, _full = opts.fullscreen or false,
               _min = opts.minimized or false}
    function w:id() return self._id end
    function w:screen() return self._screen end
    function w:isFullScreen() return self._full end
    function w:isMinimized() return self._min end
    function w:setFullScreen(state)
        self._full = state
        table.insert(calls[state and 'fullscreen' or 'unfullscreen'], self._id)
    end
    function w:minimize()
        self._min = true
        table.insert(calls.minimized, self._id)
    end
    return w
end

-- An application is its windows; the first one stands as its main window, which
-- is what layouts.lua relies on (and what reaches across spaces in the real API).
local function App(bundleID, windows)
    local a = {_id = bundleID, _windows = windows}
    function a:bundleID() return self._id end
    function a:name() return self._id end
    function a:mainWindow() return self._windows[1] end
    function a:allWindows() return self._windows end
    return a
end

-- A window that will not go fullscreen whatever it is asked -- Harvest and
-- Spotify behave exactly like this, measured: the request is accepted and
-- nothing happens.
local function StubbornWindow(id, screen)
    local win = Window(id, screen)
    function win:setFullScreen(state)
        table.insert(calls[state and 'fullscreen' or 'unfullscreen'], self._id)
    end
    return win
end

-- The same, with its window on a Space that is not the active one: allWindows()
-- reports nothing at all, mainWindow() still reaches it. Measured on a real
-- fullscreen window, and the reason layouts.lua names windows to hs.layout
-- instead of letting it enumerate them.
local function OffSpaceApp(bundleID, window)
    local a = App(bundleID, {window})
    function a:allWindows() return {} end
    return a
end

hs = {
    screen = {
        allScreens = function() return screens end,
        primaryScreen = function() return screens[1] end,
    },
    application = {
        applicationsForBundleID = function(id)
            return running[id] and {running[id]} or {}
        end,
        open = function(id) table.insert(calls.opened, id) end,
    },
    layout = {
        left25 = {x = 0, y = 0, w = 0.25, h = 1},
        left30 = {x = 0, y = 0, w = 0.3, h = 1},
        left50 = {x = 0, y = 0, w = 0.5, h = 1},
        left70 = {x = 0, y = 0, w = 0.7, h = 1},
        left75 = {x = 0, y = 0, w = 0.75, h = 1},
        right25 = {x = 0.75, y = 0, w = 0.25, h = 1},
        right30 = {x = 0.7, y = 0, w = 0.3, h = 1},
        right50 = {x = 0.5, y = 0, w = 0.5, h = 1},
        right70 = {x = 0.3, y = 0, w = 0.7, h = 1},
        right75 = {x = 0.25, y = 0, w = 0.75, h = 1},
        maximized = {x = 0, y = 0, w = 1, h = 1},
        apply = function(rows)
            for _, row in ipairs(rows) do
                table.insert(calls.layout, {
                    app = row[1]:bundleID(),
                    window = row[2] and row[2]:id() or nil,
                    screen = row[3]:id(),
                    rect = row[4],
                })
            end
        end,
    },
    timer = {doAfter = function(_, fn) fn() end}, -- fired inline: order is the test
    settings = {
        set = function(key, value) settings[key] = value end,
        get = function(key) return settings[key] end,
    },
    urlevent = {bind = function() end},
    menubar = {new = function()
        local m = {}
        function m:setTitle() return self end
        function m:setTooltip(text) calls.tooltip = text return self end
        function m:setMenu(fn) calls.menuFn = fn return self end
        return m
    end},
}

local here = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or './'
package.loaded['apps'] = dofile(here .. '../apps.lua')
local apps = package.loaded['apps']

local failed = 0
local function check(label, got, want)
    if got == want then
        print(string.format('ok    %-52s %s', label, tostring(got)))
    else
        print(string.format('FAIL  %-52s got %s, want %s',
                            label, tostring(got), tostring(want)))
        failed = failed + 1
    end
end

-- Load the module against the current screens, and return its menu items
local function load(withScreens, withApps)
    screens, running = withScreens, withApps or {}
    reset()
    package.loaded['layouts'] = nil
    dofile(here .. '../layouts.lua')
    return calls.menuFn()
end

local function itemNamed(items, title)
    for _, item in ipairs(items) do
        if item.title == title then return item end
    end
end

-- what the layout asked of one application: "screen id:rect width" or nil
local function asked(bundleID)
    for _, row in ipairs(calls.layout) do
        if row.app == bundleID then
            return row.screen .. ':' .. row.rect.w .. 'x' .. row.rect.h
        end
    end
end

-- the window the layout was handed for it, and how many rows it got
local function windowFor(bundleID)
    for _, row in ipairs(calls.layout) do
        if row.app == bundleID then return row.window end
    end
end

local function rowsFor(bundleID)
    local n = 0
    for _, row in ipairs(calls.layout) do
        if row.app == bundleID then n = n + 1 end
    end
    return n
end

local function joined(list)
    local copy = {table.unpack(list)}
    table.sort(copy)
    return table.concat(copy, ',')
end

-- Applications, all of them a single window on the built-in screen unless said
-- otherwise. Enough of them for a setup to have something to place.
local function apphouse(overrides)
    local house = {}
    for _, key in ipairs({'vivaldi', 'vscode', 'slack', 'clickup', 'sublime',
                          'discord', 'ghostty', 'spotify', 'calendar', 'finder',
                          'claude', 'harvest', 'orbstack', 'messages'}) do
        local id = apps[key]
        house[id] = App(id, {Window(key, BUILTIN)})
    end
    for key, windows in pairs(overrides or {}) do
        house[apps[key]] = App(apps[key], windows)
    end
    return house
end


-- Screen roles and setup detection -------------------------------------------

local items = load({BUILTIN}, apphouse())
check('laptop alone detects single', itemNamed(items, 'Apply layout (single screen)') ~= nil, true)

items = load({BUILTIN, LANDSCAPE}, apphouse())
check('a landscape screen detects dual', itemNamed(items, 'Apply layout (dual screen)') ~= nil, true)

items = load({BUILTIN, LANDSCAPE, PORTRAIT}, apphouse())
check('both externals detect triple', itemNamed(items, 'Apply layout (triple screen)') ~= nil, true)

items = load({LANDSCAPE, BUILTIN, PORTRAIT}, apphouse())
check('order of allScreens does not matter',
      itemNamed(items, 'Apply layout (triple screen)') ~= nil, true)

items = load({BUILTIN, PORTRAIT}, apphouse())
check('a portrait screen alone falls back to single',
      itemNamed(items, 'Apply layout (single screen)') ~= nil, true)


-- The single setup -----------------------------------------------------------

items = load({BUILTIN}, apphouse())
itemNamed(items, 'Set Single Screen Layout').fn()

check('fullscreen rows are maximized on the laptop', asked(apps.slack), '1:1x1')
check('a unit rect row keeps its rect', asked(apps.spotify), '1:0.6x0.6')
check('an offset unit rect too', asked(apps.messages), '1:0.6x0.6')
check('a minimized row is not placed', asked(apps.calendar), nil)
check('and is minimized', joined(calls.minimized), 'calendar')
check('fullscreen rows are put in fullscreen', joined(calls.fullscreen),
      'claude,clickup,discord,ghostty,orbstack,slack,sublime,vivaldi,vscode')
check('nothing else is', #calls.fullscreen, 9)


-- The triple setup -----------------------------------------------------------

items = load({BUILTIN, LANDSCAPE, PORTRAIT}, apphouse())
itemNamed(items, 'Set Triple Screen Layout').fn()

check('the horizontal screen gets Vivaldi left', asked(apps.vivaldi), '2:0.5x1')
check('and Code right', asked(apps.vscode), '2:0.5x1')
check('the vertical screen gets Ghostty on top', asked(apps.ghostty), '3:1x0.5')
check('and Calendar below', asked(apps.calendar), '3:1x0.5')
check('nothing is minimized in triple', #calls.minimized, 0)


-- Screens and applications that are not there --------------------------------

items = load({BUILTIN, LANDSCAPE}, apphouse())
itemNamed(items, 'Set Triple Screen Layout').fn() -- forced, without the vertical
check('rows for an absent screen are dropped', asked(apps.ghostty), nil)
check('and their neighbours still placed', asked(apps.vivaldi), '2:0.5x1')

local house = apphouse()
house[apps.spotify] = nil -- not running
items = load({BUILTIN}, house)
itemNamed(items, 'Set Single Screen Layout').fn()
check('a row for an application that is not running is dropped',
      asked(apps.spotify), nil)
check('the rest of the setup is still applied', asked(apps.slack), '1:1x1')


-- Leaving fullscreen, and not leaving it for nothing --------------------------

items = load({BUILTIN}, apphouse({slack = {Window('slack', BUILTIN, {fullscreen = true})}}))
itemNamed(items, 'Set Single Screen Layout').fn()
check('a window already fullscreen on the right screen is left alone',
      joined(calls.unfullscreen), '')
check('and is not placed again either', asked(apps.slack), nil)

items = load({BUILTIN, LANDSCAPE},
             apphouse({slack = {Window('slack', LANDSCAPE, {fullscreen = true})}}))
itemNamed(items, 'Set Dual Screen Layout').fn()
check('one fullscreen on the wrong screen leaves fullscreen',
      joined(calls.unfullscreen), 'slack')

items = load({BUILTIN}, apphouse({spotify = {Window('spotify', BUILTIN, {fullscreen = true})}}))
itemNamed(items, 'Set Single Screen Layout').fn()
check('a window that must be placed leaves fullscreen',
      joined(calls.unfullscreen), 'spotify')

items = load({BUILTIN}, apphouse({calendar = {Window('calendar', BUILTIN, {fullscreen = true})}}))
itemNamed(items, 'Set Single Screen Layout').fn()
check('a window that must be minimized leaves fullscreen first',
      joined(calls.unfullscreen), 'calendar')
check('then is minimized', joined(calls.minimized), 'calendar')

-- every window of an application, not just the main one
items = load({BUILTIN}, apphouse({sublime = {
    Window('sublime-main', BUILTIN),
    Window('sublime-second', BUILTIN, {fullscreen = true}),
}}))
itemNamed(items, 'Set Dual Screen Layout').fn() -- sublime is a laptop row here
check('a second window in fullscreen on a laptop row is freed too',
      joined(calls.unfullscreen), 'sublime-second')
check('but only the main window is put back in fullscreen',
      joined(calls.fullscreen),
      'calendar,claude,clickup,discord,ghostty,orbstack,slack,sublime-main')


-- Windows are named to hs.layout, never left to it -----------------------------

items = load({BUILTIN}, apphouse())
itemNamed(items, 'Set Single Screen Layout').fn()
check('the layout is given the window itself', windowFor(apps.slack), 'slack')

-- the regression this guards: allWindows() sees nothing of a window that sits on
-- another Space, so hs.layout.apply left the application where it was
local house = apphouse()
house[apps.spotify] = OffSpaceApp(apps.spotify, Window('spotify', BUILTIN))
items = load({BUILTIN}, house)
itemNamed(items, 'Set Single Screen Layout').fn()
check('a window on another Space is still placed', asked(apps.spotify), '1:0.6x0.6')
check('and named', windowFor(apps.spotify), 'spotify')

items = load({BUILTIN}, apphouse({sublime = {
    Window('sublime-main', BUILTIN),
    Window('sublime-second', BUILTIN),
}}))
itemNamed(items, 'Set Single Screen Layout').fn()
check('each window of an application gets its own row', rowsFor(apps.sublime), 2)


-- Fullscreen, one request at a time ------------------------------------------

-- an application that never accepts fullscreen must not swallow the ones after
-- it: it is asked FULLSCREEN_TRIES times, then the chain moves on
local function countIn(list, id)
    local n = 0
    for _, entry in ipairs(list) do
        if entry == id then n = n + 1 end
    end
    return n
end

house = apphouse()
house[apps.ghostty] = App(apps.ghostty, {StubbornWindow('ghostty', BUILTIN)})
items = load({BUILTIN}, house)
itemNamed(items, 'Set Single Screen Layout').fn()
check('a window that refuses fullscreen is retried, not insisted on',
      countIn(calls.fullscreen, 'ghostty'), 3)
check('and the rows after it still get theirs',
      countIn(calls.fullscreen, 'slack'), 1)
check('as do the rows before', countIn(calls.fullscreen, 'vivaldi'), 1)

-- one that accepts is asked exactly once
items = load({BUILTIN}, apphouse())
itemNamed(items, 'Set Single Screen Layout').fn()
check('a window that accepts is asked once', countIn(calls.fullscreen, 'ghostty'), 1)


-- Tooltip, and what survives a reload ----------------------------------------

settings = {} -- a machine that has never applied one, hs.settings being persistent
items = load({BUILTIN, LANDSCAPE}, apphouse())
check('tooltip after a load with nothing remembered', calls.tooltip, 'No Layout')
itemNamed(items, 'Set Dual Screen Layout').fn()
check('tooltip after applying', calls.tooltip, 'Dual screen layout')
check('the setup is remembered', settings['layouts.applied'], 'dual')

load({BUILTIN, LANDSCAPE}, apphouse()) -- reload, same settings
check('tooltip restored on the next load', calls.tooltip, 'Dual screen layout')


-- Launching ------------------------------------------------------------------

house = apphouse()
house[apps.discord] = nil
items = load({BUILTIN}, house)
itemNamed(items, 'Launch Apps').fn()
check('only what is not running is launched', joined(calls.opened), apps.discord)


print(failed == 0 and '\nALL PASS' or ('\n' .. failed .. ' FAILURE(S)'))
os.exit(failed == 0 and 0 or 1)
