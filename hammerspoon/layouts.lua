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
        {"Vivaldi", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"Code", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"Slack", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"ClickUp", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"Sublime Text", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"Discord", nil, monitors.laptop, hs.layout.maximized, nil, nil},
    },
    windowed = {
        {"Spotify", nil, monitors.laptop, layout.spotify, nil, nil},
    }
}

local layoutTripleScreen = {
    fullscreen = {
        {"Slack", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"ClickUp", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"Sublime Text", nil, monitors.laptop, hs.layout.maximized, nil, nil},
        {"Discord", nil, monitors.laptop, hs.layout.maximized, nil, nil},
    },
    windowed = {
        {"Spotify", nil, monitors.laptop, layout.spotify, nil, nil},
        {"Vivaldi", nil, monitors.home.left, hs.layout.left50, nil, nil},
        {"Code", nil, monitors.home.left, hs.layout.right50, nil, nil},
    }
}

local appNames = {
    "Vivaldi",
    "Slack",
    "Discord",
    "Spotify",
    "Finder",
    "Sublime Text",
    "ClickUp",
    "Code",
}

-- Closed apps or apps without windows must not abort the whole layout
local function setFullscreenState(appList, state)
    for _, v in ipairs(appList) do
        local app = hs.appfinder.appFromName(v[1])
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
    for i, appname in ipairs(appNames) do
        local app = hs.appfinder.appFromName(appname)
        if app == nil then
            hs.application.open(appname)
        end
    end
end

local menu = hs.menubar.new()
if not menu then return end

local function setSingleScreen()
    menu:setTooltip("Single Screen Layout")
    unFullscreen(layoutSingleScreen.windowed)
    hs.timer.doAfter(0.5, function()
        hs.layout.apply(layoutSingleScreen.windowed)
        hs.layout.apply(layoutSingleScreen.fullscreen)
        toFullscreen(layoutSingleScreen.fullscreen)
    end)
end

local function setTripleScreen()
    menu:setTooltip("Triple Screen Layout")
    unFullscreen(layoutTripleScreen.windowed)
    hs.timer.doAfter(0.5, function()
        hs.layout.apply(layoutTripleScreen.windowed)
        hs.layout.apply(layoutTripleScreen.fullscreen)
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
