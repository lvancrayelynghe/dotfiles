local apps = require('apps')

-- Screens are identified by role rather than by name. A name is localised (see
-- the handler at the bottom) and, on two identical monitors, "(1)" and "(2)" are
-- an ordering macOS assigns and can swap from one reconnection to the next --
-- nothing there is tied to a panel. Shape is: the vertical screen is the one
-- taller than it is wide. The Mac's own screen is the exception, nothing in
-- hs.screen identifying it -- getInfo() returns nil in this version and
-- CGDisplayIsBuiltin is not exposed -- so it goes by the "Built-in" prefix that
-- NSScreen gives every built-in display, with the primary screen as a fallback.
local function currentScreens()
    local all = hs.screen.allScreens()

    local laptop
    for _, screen in ipairs(all) do
        if (screen:name() or ''):find('^Built%-in') then
            laptop = screen
            break
        end
    end
    laptop = laptop or hs.screen.primaryScreen()

    local screens = {laptop = laptop}
    for _, screen in ipairs(all) do
        if not laptop or screen:id() ~= laptop:id() then
            local frame = screen:fullFrame()
            local role = frame.h > frame.w and 'vertical' or 'horizontal'
            screens[role] = screens[role] or screen -- first one wins
        end
    end
    return screens
end

-- The setup the screens currently plugged in call for. A vertical screen on its
-- own falls through to single: no layout here places anything on it alone.
local function detectSetup(screens)
    if screens.horizontal and screens.vertical then return 'triple' end
    if screens.horizontal then return 'dual' end
    return 'single'
end

-- Unit rects hs.layout does not define
local unit = {
    top50 = {x = 0, y = 0, w = 1, h = 0.5},
    bottom50 = {x = 0, y = 0.5, w = 1, h = 0.5},
    spotify = {x = 0, y = 0, w = 0.6, h = 0.6},
    messages = {x = 0.01, y = 0.03, w = 0.6, h = 0.6},
}

-- One list per setup, of {bundle id, screen role, target} rows, the target being
-- either a unit rect to place the window in or the window state to put it in:
-- 'fullscreen' or 'minimized'.
--
-- This used to be two lists, fullscreen and windowed, which never described two
-- kinds of row -- only what apply() did with each list. The state belongs to the
-- row, all the more so now that there are three of them: as separate lists it
-- would take a third one, and a fourth for whatever comes next. hs.layout is no
-- help here, exposing unit rects only (left25 .. right75, maximized) and knowing
-- nothing of window states -- no hs.layout.minimized, and no fullscreen either.
--
-- The laptop rows are deliberately identical in dual and triple, so that
-- switching between those two never has to take a window out of fullscreen.
local setups = {
    single = {
        {apps.vivaldi, 'laptop', 'fullscreen'},
        {apps.vscode, 'laptop', 'fullscreen'},

        {apps.ghostty, 'laptop', 'fullscreen'},
        {apps.calendar, 'laptop', 'minimized'},
        {apps.orbstack, 'laptop', 'fullscreen'},

        {apps.slack, 'laptop', 'fullscreen'},
        {apps.clickup, 'laptop', 'fullscreen'},
        {apps.sublime, 'laptop', 'fullscreen'},
        {apps.discord, 'laptop', 'fullscreen'},
        {apps.claude, 'laptop', 'fullscreen'},
        {apps.spotify, 'laptop', unit.spotify},
        {apps.messages, 'laptop', unit.messages},
    },
    dual = {
        {apps.vivaldi, 'horizontal', hs.layout.left50},
        {apps.vscode, 'horizontal', hs.layout.right50},

        {apps.ghostty, 'laptop', 'fullscreen'},
        {apps.calendar, 'laptop', 'fullscreen'},
        {apps.orbstack, 'laptop', 'fullscreen'},

        {apps.slack, 'laptop', 'fullscreen'},
        {apps.clickup, 'laptop', 'fullscreen'},
        {apps.sublime, 'laptop', 'fullscreen'},
        {apps.discord, 'laptop', 'fullscreen'},
        {apps.claude, 'laptop', 'fullscreen'},
        {apps.spotify, 'laptop', unit.spotify},
        {apps.messages, 'laptop', unit.messages},
    },
    triple = {
        {apps.vivaldi, 'horizontal', hs.layout.left50},
        {apps.vscode, 'horizontal', hs.layout.right50},

        {apps.ghostty, 'vertical', unit.top50},
        {apps.calendar, 'vertical', unit.bottom50},
        {apps.orbstack, 'vertical', unit.bottom50},

        {apps.slack, 'laptop', 'fullscreen'},
        {apps.clickup, 'laptop', 'fullscreen'},
        {apps.sublime, 'laptop', 'fullscreen'},
        {apps.discord, 'laptop', 'fullscreen'},
        {apps.claude, 'laptop', 'fullscreen'},
        {apps.spotify, 'laptop', unit.spotify},
        {apps.messages, 'laptop', unit.messages},
    },
}

-- The rows of a setup asking for one particular state
local function rowsWanting(rows, target)
    local found = {}
    for _, row in ipairs(rows) do
        if row[3] == target then
            table.insert(found, row)
        end
    end
    return found
end

local appsToLaunch = {
    apps.vivaldi,
    apps.harvest,
    apps.slack,
    apps.discord,
    apps.spotify,
    apps.finder,
    apps.sublime,
    apps.clickup,
    apps.vscode,
    apps.ghostty,
    apps.claude,
}

-- Every window of an application, which takes two calls: allWindows() does not
-- see a window that is fullscreen, macOS having given it a space of its own, and
-- mainWindow() sees that one but none of the others. Measured on a fullscreen
-- Slack window: absent from allWindows(), returned by mainWindow().
local function windowsOf(bundleID)
    local app = hs.application.applicationsForBundleID(bundleID)[1]
    if not app then return {} end

    local windows, seen = {}, {}
    local main = app:mainWindow()
    if main then
        seen[main:id() or -1] = true
        table.insert(windows, main)
    end
    for _, win in ipairs(app:allWindows()) do
        local id = win:id() or -1
        if not seen[id] then
            seen[id] = true
            table.insert(windows, win)
        end
    end
    return windows, main
end

-- macOS neither moves, resizes nor minimizes a window that is in fullscreen, so
-- anything that has to change must leave it first -- every window of the
-- application, since hs.layout.apply, given no window title, places them all
-- (layout.lua:200). A closed application, or one without windows, must not abort
-- the whole layout.
--
-- Exactly one window may stay: the main one, when its row asks for fullscreen and
-- it already is, on the right screen. Leaving and re-entering fullscreen for
-- nothing is both slow and very visible. Any other window of that application
-- still has to come out, main being the only one toFullscreen() puts back.
local function leaveFullscreen(rows, screens)
    for _, row in ipairs(rows) do
        local wanted = screens[row[2]]
        local windows, main = windowsOf(row[1])
        for _, win in ipairs(windows) do
            if win:isFullScreen() then
                local screen = win:screen()
                local staying = row[3] == 'fullscreen'
                    and main and win:id() == main:id()
                    and wanted and screen and screen:id() == wanted:id()
                if not staying then
                    win:setFullScreen(false)
                end
            end
        end
    end
end

-- Entering fullscreen is for the main window only: macOS gives each fullscreen
-- window a space of its own, and the second Sublime window wants none.
--
-- One at a time, and that is the whole difficulty. macOS serialises these
-- transitions and silently drops any request made while another is going
-- through: measured, four fired in a single tick left two of the four windowed,
-- while the same four spaced 0.9 s apart left only the one application that
-- never accepts fullscreen at all. Hence a chain rather than a loop, each request
-- checked once its transition has had time to finish and retried a couple of
-- times -- then given up on, because some applications (Harvest, Spotify) have no
-- fullscreen state to set and asking forever is what makes macOS play its "no"
-- sound. A window already fullscreen costs nothing: it is skipped immediately.
local FULLSCREEN_GAP, FULLSCREEN_TRIES = 0.9, 3

local function toFullscreen(rows, index, attempt)
    index, attempt = index or 1, attempt or 1
    local row = rows[index]
    if not row then return end

    local app = hs.application.applicationsForBundleID(row[1])[1]
    local win = app and app:mainWindow()
    if not win or win:isFullScreen() then
        return toFullscreen(rows, index + 1, 1)
    end

    win:setFullScreen(true)
    hs.timer.doAfter(FULLSCREEN_GAP, function()
        if win:isFullScreen() or attempt >= FULLSCREEN_TRIES then
            toFullscreen(rows, index + 1, 1)
        else
            toFullscreen(rows, index, attempt + 1)
        end
    end)
end

-- Minimizing, on the other hand, covers every window: the point is to get the
-- application out of the way, and a second window left on screen would defeat it.
local function minimize(rows)
    for _, row in ipairs(rows) do
        for _, win in ipairs(windowsOf(row[1])) do
            if not win:isMinimized() then
                win:minimize()
            end
        end
    end
end

local function launchApps()
    for _, bundleID in ipairs(appsToLaunch) do
        if hs.application.applicationsForBundleID(bundleID)[1] == nil then
            hs.application.open(bundleID)
        end
    end
end

-- hs.layout rows, built from ours. It takes an application name or an
-- hs.application object, never a bundle id, and a screen name or an hs.screen
-- object, never a role (layout.lua:147-175).
--
-- The windows are named explicitly, one row each, and that is the whole point:
-- left to find them itself, hs.layout.apply calls app:allWindows()
-- (layout.lua:200), which only ever sees the Space currently active on each
-- screen. A window sitting on any other Space -- which is where every fullscreen
-- window and everything left behind on another desktop lives -- is invisible to
-- it, so it logs "No windows matched, skipping" and the application simply does
-- not move. Measured on a fullscreen Slack window: allWindows() returned nothing
-- at all, and still nothing 2.5 s after it had left fullscreen. That is what made
-- a layout need applying twice -- the first run only freed the windows from
-- fullscreen, which brought them back onto an ordinary Space for the second.
-- Given a window in slot 2, hs.layout.apply uses that one and enumerates nothing
-- (layout.lua:186-188), and windowsOf() finds it through mainWindow(), which does
-- reach across Spaces.
--
-- Rows whose application is not running, whose screen is not plugged in, or whose
-- windows cannot be reached are dropped; so are the rows asking to be minimized,
-- placing a window one is about to put away being work for nothing. A window
-- still in fullscreen here is one leaveFullscreen() deliberately kept there,
-- everything else having been asked to leave before this runs: there is nothing
-- to place, and macOS would refuse anyway.
local function resolve(rows, screens)
    local resolved = {}
    for _, row in ipairs(rows) do
        local app = hs.application.applicationsForBundleID(row[1])[1]
        local screen = screens[row[2]]
        local rect = row[3] == 'fullscreen' and hs.layout.maximized or row[3]
        if app and screen and type(rect) == 'table' then
            for _, win in ipairs(windowsOf(row[1])) do
                if not win:isFullScreen() then
                    table.insert(resolved, {app, win, screen, rect, nil, nil})
                end
            end
        end
    end
    return resolved
end

local menu = hs.menubar.new()
if not menu then return end

-- Which layout was applied last, so that the tooltip survives a config reload --
-- and this config reloads on every save.
local SETTING = 'layouts.applied'

local function tooltipFor(name)
    if not name then return "No Layout" end
    return name:gsub('^%l', string.upper) .. ' screen layout'
end

local function apply(name)
    local setup = setups[name]
    if not setup then return end

    local screens = currentScreens()
    hs.settings.set(SETTING, name)
    menu:setTooltip(tooltipFor(name))

    -- The delay covers the fullscreen transitions leaveFullscreen() just asked
    -- for, and 0.5 s is comfortable rather than tight: measured, a setFrame sent
    -- 100 ms after setFullScreen(false) holds, and so does a move to another
    -- screen. What cannot be waited on is isFullScreen(), which flips to false
    -- the instant the call is made -- so polling it, the obvious "improvement"
    -- here, would wait for nothing at all.
    leaveFullscreen(setup, screens)
    hs.timer.doAfter(0.5, function()
        hs.layout.apply(resolve(setup, screens))
        -- minimizing first, since toFullscreen() then runs on its own timers and
        -- would otherwise have the two competing for the window server
        minimize(rowsWanting(setup, 'minimized'))
        toFullscreen(rowsWanting(setup, 'fullscreen'))
    end)
end

-- A function rather than a table, so that the detected setup is worked out when
-- the menu is opened rather than once at load: plugging a screen in changes it.
local function enableMenu()
    menu:setTitle("🖥")
    menu:setTooltip(tooltipFor(hs.settings.get(SETTING)))
    menu:setMenu(function()
        local detected = detectSetup(currentScreens())
        return {
            {title = "Launch Apps", fn = launchApps},
            {title = "Apply layout (" .. detected .. " screen)",
             fn = function() apply(detected) end},
            {title = "-"},
            {title = "Set Single Screen Layout", fn = function() apply('single') end},
            {title = "Set Dual Screen Layout", fn = function() apply('dual') end},
            {title = "Set Triple Screen Layout", fn = function() apply('triple') end},
        }
    end)
end

enableMenu()

-- Screens as Hammerspoon sees them, for `screenid` in shell/aliases-macos.sh:
--     open -g "hammerspoon://screens"
-- Nothing above needs those names any more, but they are still the only way to
-- check what Hammerspoon thinks is plugged in, and they exist in this form
-- nowhere else: hs.screen:name() is NSScreen.localizedName (libscreen.m:78),
-- localised for the *calling* application, and Hammerspoon ships English only --
-- ask macOS the same question from a terminal and it answers "Écran Retina
-- intégré". The UUID comes along as the one identifier tied to a panel.
hs.urlevent.bind("screens", function()
    local screens = currentScreens()
    local roles = {}
    for role, screen in pairs(screens) do
        roles[screen:id()] = role
    end

    local primary = hs.screen.primaryScreen()
    local lines = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        local frame = screen:fullFrame()
        table.insert(lines, string.format('%-12s %-26s %s  %dx%d at %d,%d%s',
            roles[screen:id()] or '-', tostring(screen:name()),
            tostring(screen:getUUID()), frame.w, frame.h, frame.x, frame.y,
            screen:id() == primary:id() and '  [primary]' or ''))
    end
    table.insert(lines, 'setup: ' .. detectSetup(screens))

    local file = io.open(os.getenv('HOME') .. '/.cache/hammerspoon-screens.txt', 'w')
    if file then
        file:write(table.concat(lines, '\n'), '\n')
        file:close()
    end
end)
