local apps = require('apps')

local monitors = {
    laptop = "Built-in Retina Display",
    home = {
        left = "LG HDR 4K (1)",
        right = "LG HDR 4K (2)"
    }
}

local layout = {
    leftTop = {x=0, y=0, w=0.5, h=0.5},
    leftBottom = {x=0, y=0.5, w=0.5, h=0.5},
    rightTop = {x=0.5, y=0, w=0.5, h=0.5},
    rightBottom = {x=0.5, y=0.5, w=0.5, h=0.5},
    top50 = {x=0, y=0, w=1, h=0.5},
    spotify = {x=0, y=0, w=0.6, h=0.6},
}

local layoutSingleScreen = {
    fullscreen = {
        {apps.vivaldi, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.vscode, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.slack, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.clickup, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.sublime, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.discord, nil, monitors.laptop, hs.layout.maximized, nil, nil},
    },
    windowed = {
        {apps.spotify, nil, monitors.laptop, layout.spotify, nil, nil},
    }
}

local layoutTripleScreen = {
    fullscreen = {
        {apps.slack, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.clickup, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.sublime, nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {apps.discord, nil, monitors.laptop, hs.layout.maximized, nil, nil},
    },
    windowed = {
        {apps.spotify, nil, monitors.laptop, layout.spotify, nil, nil},
        {apps.vivaldi, nil, monitors.home.left, hs.layout.left50, nil, nil},
        {apps.vscode, nil, monitors.home.left, hs.layout.right50, nil, nil},
    }
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

-- Closed apps or apps without windows must not abort the whole layout
local function setFullscreenState(appList, state)
    for _, v in ipairs(appList) do
        local app = hs.application.applicationsForBundleID(v[1])[1]
        local win = app and app:mainWindow()
        if win and win:isFullScreen() ~= state then
            win:setFullScreen(state)
        end
    end
end

local function unFullscreen(appList)
    setFullscreenState(appList, false)
end

local function toFullscreen(appList)
    setFullscreenState(appList, true)
end

local function launchApps()
    for _, bundleID in ipairs(appsToLaunch) do
        if hs.application.applicationsForBundleID(bundleID)[1] == nil then
            hs.application.open(bundleID)
        end
    end
end

-- hs.layout.apply takes an application name or an hs.application object, never
-- a bundle id (layout.lua:147-155), and a name is what we are getting away from.
-- So resolve here, dropping whatever is not running rather than passing nil,
-- which would only make it print "No windows matched" for each.
local function resolve(appList)
    local resolved = {}
    for _, v in ipairs(appList) do
        local app = hs.application.applicationsForBundleID(v[1])[1]
        if app then
            table.insert(resolved, {app, v[2], v[3], v[4], v[5], v[6]})
        end
    end
    return resolved
end

local menu = hs.menubar.new()
if not menu then return end

local function setSingleScreen()
    menu:setTooltip("Single Screen Layout")
    unFullscreen(layoutSingleScreen.windowed)
    hs.timer.doAfter(0.5, function()
        hs.layout.apply(resolve(layoutSingleScreen.windowed))
        hs.layout.apply(resolve(layoutSingleScreen.fullscreen))
        toFullscreen(layoutSingleScreen.fullscreen)
    end)
end

local function setTripleScreen()
    menu:setTooltip("Triple Screen Layout")
    unFullscreen(layoutTripleScreen.windowed)
    hs.timer.doAfter(0.5, function()
        hs.layout.apply(resolve(layoutTripleScreen.windowed))
        hs.layout.apply(resolve(layoutTripleScreen.fullscreen))
        toFullscreen(layoutTripleScreen.fullscreen)
    end)
end

local function enableMenu()
    menu:setTitle("🖥")
    menu:setTooltip("No Layout")
    menu:setMenu({
        { title = "Launch Apps", fn = launchApps },
        { title = "Set Single Screen Layout", fn = setSingleScreen },
        { title = "Set Triple Screen Layout", fn = setTripleScreen },
    })
end

enableMenu()
