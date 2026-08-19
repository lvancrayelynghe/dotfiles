-- Caffeinate
local caffeine = hs.menubar.new()

-- Dim the screen on idle, while still caffeinated
--
-- `displayIdle` keeps the screen on; this keeps it from burning a full backlight
-- for hours with nobody in front of it. macOS offers no middle state -- an
-- assertion is all-or-nothing, and its own pre-sleep dim never runs while one is
-- held -- so the dimming is driven from here, off the HID idle timer.
--
-- Three measurements make that possible, none of them obvious:
--   * hs.host.idleTime() keeps counting under the assertion (traced past 78 s
--     with it held). Assertions suppress the power-management timer, they do not
--     inject activity; only hs.caffeinate.declareUserActivity() would reset it.
--   * setting the brightness does *not* reset that idle timer, so the dim cannot
--     feed itself a wake-up.
--   * the ambient light sensor does not fight the value back.
local DIM_AFTER = 300   -- seconds without input before the screen dims
local DIM_LEVEL = 0.05  -- brightness to fall to, 0..1 -- never raises a screen
local FADE_TIME = 1     -- how long the fade down takes; waking back up is instant
local FADE_TICK = 0.05
local DIM_POLL = 2      -- backstop poll while dimmed, in case the eventtap dies

-- Global on purpose, and the reason this is one table rather than a handful of
-- locals: a timer or an eventtap reachable only from a chunk-local is
-- garbage-collected and silently stops -- hs.eventtap's __gc disables the tap
-- outright. Measured while writing this, in this very file's directory: a bare
-- `hs.timer.doAfter(0.4, fn)` never fired once.
caffeineDim = {watching = false, dimmed = false, saved = nil,
               timer = nil, fade = nil, tap = nil, watcher = nil}

-- hs.screen:setBrightness() rather than hs.brightness.set(): the latter is
-- built-in-only and works in integer percents, which loses a point on the way
-- through -- set(38) reads back 37, so a restore never lands where it started.
-- The per-screen call takes a 0..1 float and round-trips exactly (measured drift
-- 0.0000), and it is tried on every screen, so an external display that supports
-- it dims too while one that does not simply ignores the call.
local function snapshot()
    local levels = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        local ok, level = pcall(screen.getBrightness, screen)
        if ok and type(level) == "number" and level >= 0 and level <= 1 then
            levels[#levels + 1] = {screen = screen, level = level}
        end
    end
    return levels
end

-- pcall: a screen can be unplugged between the snapshot and the restore
local function applyBrightness(entry, level)
    pcall(entry.screen.setBrightness, entry.screen, level)
end

-- Both stop the object without dropping the reference, and that is deliberate:
-- each is called from inside its own callback -- stopFade() on the fade's last
-- step, stopTap() through undim() from the tap that just fired -- so clearing
-- the field there would leave a live object with nothing pointing at it, free to
-- be collected while its own callback is still on the stack. The stale value
-- costs nothing and is overwritten by the next dim().
local function stopFade()
    if caffeineDim.fade then caffeineDim.fade:stop() end
end

local function stopTap()
    if caffeineDim.tap then caffeineDim.tap:stop() end
end

-- Instant and unconditional. Also called on sleep, on lock and on reload, where
-- leaving the dim level in place is not cosmetic: macOS remembers the brightness
-- across a sleep, so a machine that sleeps dimmed wakes up at 5% for good.
local function undim()
    stopFade()
    stopTap()
    if caffeineDim.saved then
        for _, entry in ipairs(caffeineDim.saved) do
            applyBrightness(entry, entry.level)
        end
        caffeineDim.saved = nil
    end
    caffeineDim.dimmed = false
end

local tick -- the watch loop reschedules itself, so the name has to exist first

local function schedule(delay)
    if caffeineDim.timer then caffeineDim.timer:stop() end
    caffeineDim.timer = hs.timer.doAfter(delay, tick)
end

-- systemDefined carries the brightness and media keys, which are not keyDown:
-- without it, reaching for F1/F2 in the dark would be answered by the backstop
-- poll a second or two later instead of at once.
local WAKE_EVENTS = {
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.flagsChanged,
    hs.eventtap.event.types.mouseMoved,
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.rightMouseDown,
    hs.eventtap.event.types.otherMouseDown,
    hs.eventtap.event.types.scrollWheel,
    hs.eventtap.event.types.systemDefined,
}

local function dim()
    caffeineDim.saved = snapshot()
    if #caffeineDim.saved == 0 then return end
    caffeineDim.dimmed = true

    -- The tap exists only while dimmed: watching every mouse move is not
    -- something to leave running, and one event is all it ever needs to see.
    stopTap()
    caffeineDim.tap = hs.eventtap.new(WAKE_EVENTS, function()
        undim()
        schedule(DIM_AFTER)
        return false -- the event that woke the screen must still reach its app
    end):start()

    stopFade()
    local steps = math.floor(FADE_TIME / FADE_TICK)
    local step = 0
    caffeineDim.fade = hs.timer.doEvery(FADE_TICK, function()
        step = step + 1
        local ratio = math.min(1, step / steps)
        -- `or {}`: undim() may have run between two ticks of this fade
        for _, entry in ipairs(caffeineDim.saved or {}) do
            local target = math.min(DIM_LEVEL, entry.level)
            applyBrightness(entry, entry.level + (target - entry.level) * ratio)
        end
        if step >= steps then stopFade() end
    end)
end

tick = function()
    if not hs.caffeinate.get("displayIdle") then
        caffeineDim.watching = false
        undim()
        return
    end

    local idle = hs.host.idleTime()
    if caffeineDim.dimmed then
        -- The eventtap is what actually wakes the screen; this branch is the
        -- backstop for the case where macOS disables the tap behind our back.
        if idle < DIM_AFTER then
            undim()
            schedule(DIM_AFTER - idle)
        else
            schedule(DIM_POLL)
        end
    elseif idle >= DIM_AFTER then
        dim()
        schedule(DIM_POLL)
    else
        -- Sleep exactly long enough to reach the threshold rather than polling:
        -- one wake-up per DIM_AFTER of continuous use, not one per second.
        schedule(math.max(0.5, DIM_AFTER - idle))
    end
end

-- tick() rather than schedule(DIM_AFTER): the assertion is not necessarily
-- turned on by a hand that just touched something -- a reload, or anything
-- reaching the url event, arrives with idle time already on the clock. Arming a
-- full delay there restarts a countdown that was two thirds done, and a screen
-- idle well past the threshold sits bright until the timer catches up. Found by
-- tracing the live module: idle ran from 30 to 41 s with nothing dimming.
local function startDimWatch()
    if caffeineDim.watching then return end
    caffeineDim.watching = true
    tick()
end

local function stopDimWatch()
    caffeineDim.watching = false
    if caffeineDim.timer then
        caffeineDim.timer:stop()
        caffeineDim.timer = nil
    end
    undim()
end

caffeineDim.watcher = hs.caffeinate.watcher.new(function(event)
    local w = hs.caffeinate.watcher
    if event == w.systemWillSleep or event == w.screensDidSleep
        or event == w.screensDidLock or event == w.systemWillPowerOff then
        undim()
    elseif event == w.systemDidWake or event == w.screensDidUnlock then
        if caffeineDim.watching then schedule(DIM_AFTER) end
    end
end):start()

-- A reload destroys the Lua state without touching the backlight, so a dim level
-- left behind becomes the new brightness. Chained rather than assigned:
-- hs.shutdownCallback is a single slot, and this file is not its only claimant.
local previousShutdown = hs.shutdownCallback
hs.shutdownCallback = function()
    undim()
    if previousShutdown then previousShutdown() end
end

-- The menubar item, and the assertion itself
--
-- Every path that changes the assertion goes through setCaffeineDisplay, which
-- is therefore the one place the dim watch has to be started and stopped -- the
-- call at the bottom of this file covers the reload case too, where the
-- assertion outlives the Lua state that was watching it.
local function setCaffeineDisplay(state)
    if state then startDimWatch() else stopDimWatch() end

    if not caffeine then return end
    if state then
        caffeine:setTitle("☕️")
        caffeine:setTooltip("Caffeinated!")
    else
        caffeine:setTitle("💤")
        caffeine:setTooltip("No caffeine :(")
    end
end

local function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
    caffeine:setClickCallback(caffeineClicked)
end
setCaffeineDisplay(hs.caffeinate.get("displayIdle"))

-- Same toggle from a terminal, through the `caffeine` function in
-- shell/aliases-macos.sh:
--     open -g "hammerspoon://caffeinate?action=toggle"   (or on, or off)
-- The hammerspoon:// scheme is claimed by the app itself (CFBundleURLSchemes),
-- so this needs nothing installed and no setting turned on, unlike hs.ipc or
-- hs.allowAppleScript. Going through here rather than calling `caffeinate -d`
-- in the shell also keeps one holder of the assertion, hence a menubar icon
-- that cannot disagree with the actual state.
hs.urlevent.bind("caffeinate", function(_, params)
    local action = params and params.action or "toggle"
    if action == "toggle" then
        setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
    elseif action == "on" or action == "off" then
        hs.caffeinate.set("displayIdle", action == "on")
        setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
    end
end)
