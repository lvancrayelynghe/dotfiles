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
}

-- Rows are hs.layout rows with a screen *role* where the screen goes:
-- {bundle id, window title, role, unit rect, frame rect, full-frame rect}.
-- resolve() swaps the id and the role for live objects just before applying.
-- The laptop group is deliberately the same in dual and triple, so that
-- switching between the two never has to move a window that is already
-- fullscreen (macOS would refuse: see unFullscreen below).
local setups = {
    single = {
        fullscreen = {
            {apps.vivaldi, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.vscode, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.slack, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.clickup, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.sublime, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.discord, nil, 'laptop', hs.layout.maximized, nil, nil},
        },
        windowed = {
            {apps.spotify, nil, 'laptop', unit.spotify, nil, nil},
        },
    },
    dual = {
        fullscreen = {
            {apps.slack, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.clickup, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.sublime, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.discord, nil, 'laptop', hs.layout.maximized, nil, nil},
        },
        windowed = {
            {apps.spotify, nil, 'laptop', unit.spotify, nil, nil},
            {apps.vivaldi, nil, 'horizontal', hs.layout.left50, nil, nil},
            {apps.vscode, nil, 'horizontal', hs.layout.right50, nil, nil},
        },
    },
    triple = {
        fullscreen = {
            {apps.slack, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.clickup, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.sublime, nil, 'laptop', hs.layout.maximized, nil, nil},
            {apps.discord, nil, 'laptop', hs.layout.maximized, nil, nil},
        },
        windowed = {
            {apps.spotify, nil, 'laptop', unit.spotify, nil, nil},
            {apps.vivaldi, nil, 'horizontal', hs.layout.left50, nil, nil},
            {apps.vscode, nil, 'horizontal', hs.layout.right50, nil, nil},
            {apps.ghostty, nil, 'vertical', unit.top50, nil, nil},
            {apps.calendar, nil, 'vertical', unit.bottom50, nil, nil},
        },
    },
}

local appsToLaunch = {
    apps.vivaldi,
    apps.slack,
    apps.discord,
    apps.spotify,
    apps.finder,
    apps.sublime,
    apps.clickup,
    apps.vscode,
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
    return windows
end

-- Leaving fullscreen covers every window: any of them could be the one
-- hs.layout.apply is about to try to move, and macOS moves no fullscreen window.
-- A closed application, or one without windows, must not abort the whole layout.
local function unFullscreen(rows)
    for _, row in ipairs(rows) do
        for _, win in ipairs(windowsOf(row[1])) do
            if win:isFullScreen() then
                win:setFullScreen(false)
            end
        end
    end
end

-- Entering it is for the main window only: macOS gives each fullscreen window a
-- space of its own, and the second Sublime window wants none.
local function toFullscreen(rows)
    for _, row in ipairs(rows) do
        local app = hs.application.applicationsForBundleID(row[1])[1]
        local win = app and app:mainWindow()
        if win and not win:isFullScreen() then
            win:setFullScreen(true)
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

-- hs.layout.apply takes an application name or an hs.application object, never a
-- bundle id, and a screen name or an hs.screen object, never a role
-- (layout.lua:147-175). Resolve both here, dropping the rows whose application
-- is not running or whose screen is not plugged in: passing nil would only make
-- it log "No windows matched" for each of them.
local function resolve(rows, screens)
    local resolved = {}
    for _, row in ipairs(rows) do
        local app = hs.application.applicationsForBundleID(row[1])[1]
        local screen = screens[row[3]]
        if app and screen then
            table.insert(resolved, {app, row[2], screen, row[4], row[5], row[6]})
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

    -- macOS will not move or resize a window that is in fullscreen, so leave it
    -- first. The delay covers that transition, and 0.5 s is comfortable rather
    -- than tight: measured, a setFrame sent 100 ms after setFullScreen(false)
    -- holds, and so does a move to another screen. What cannot be waited on is
    -- isFullScreen(), which flips to false the instant the call is made -- so
    -- polling it, the obvious "improvement" here, would wait for nothing at all.
    unFullscreen(setup.windowed)
    hs.timer.doAfter(0.5, function()
        hs.layout.apply(resolve(setup.windowed, screens))
        hs.layout.apply(resolve(setup.fullscreen, screens))
        toFullscreen(setup.fullscreen)
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
