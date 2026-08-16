-- Tests for caffeinate.lua, run outside Hammerspoon:
--
--     lua hammerspoon/tests/test-caffeinate.lua
--
-- The module exports nothing, so it is driven the way the machine drives it: the
-- stub captures the menubar click callback, the urlevent handler, the timers,
-- the eventtap and the sleep watcher, and the tests fire them by hand. Time is
-- not real here -- hs.host.idleTime() is a variable the test sets, and a timer
-- runs only when the test says so -- which is what makes a minute-long threshold
-- and a fade of any length testable at all.
--
-- No delay is repeated from the module either: DIM_AFTER is read back from the
-- one timer a caffeinated load arms, and every fixture below is a fraction of
-- it. Verified to hold unchanged from a 10 s threshold to a 600 s one.
--
-- The assertions that matter are about brightness arithmetic: that a restore
-- lands exactly where the snapshot was taken (the reason for the 0..1 per-screen
-- API over hs.brightness's integer percents), and that no path can leave a
-- screen dimmed -- sleep, lock, reload, or the assertion being dropped.

local failed = 0

local function check(label, got, want)
    if got == want then
        print(string.format('ok    %-54s %s', label, tostring(got)))
    else
        print(string.format('FAIL  %-54s got %s, want %s',
                            label, tostring(got), tostring(want)))
        failed = failed + 1
    end
end

-- Stub state ------------------------------------------------------------------

local idle, assertions, screens = 0, {}, {}
local timers, taps, watchers, menu, urlHandler, clickCallback

local function reset()
    idle, assertions = 0, {}
    timers, taps, watchers = {}, {}, {}
    menu = {title = nil, tooltip = nil}
    urlHandler, clickCallback = nil, nil
end

-- A screen whose brightness is a plain number. `supported = false` models an
-- external display that answers nothing useful, `errors = true` one that throws.
local function Screen(name, level, opts)
    opts = opts or {}
    local s = {_name = name, level = level, sets = 0}
    function s:name() return self._name end
    function s:getBrightness()
        if opts.errors then error('no brightness on ' .. self._name) end
        if opts.supported == false then return -1 end
        return self.level
    end
    function s:setBrightness(value)
        self.sets = self.sets + 1
        self.level = value
        return self
    end
    return s
end

local function Timer(delay, fn, repeating)
    local t = {delay = delay, fn = fn, repeating = repeating, running = true}
    function t:stop() self.running = false; return self end
    timers[#timers + 1] = t
    return t
end

hs = {
    menubar = {
        new = function()
            local m = {}
            function m:setTitle(v) menu.title = v; return self end
            function m:setTooltip(v) menu.tooltip = v; return self end
            function m:setClickCallback(fn) clickCallback = fn; return self end
            return m
        end,
    },
    caffeinate = {
        get = function(kind) return assertions[kind] or false end,
        set = function(kind, state) assertions[kind] = state end,
        toggle = function(kind)
            assertions[kind] = not (assertions[kind] or false)
            return assertions[kind]
        end,
        watcher = {
            systemWillSleep = 1, systemDidWake = 2, systemWillPowerOff = 3,
            screensDidSleep = 4, screensDidLock = 5, screensDidUnlock = 6,
            new = function(fn)
                local w = {fn = fn, running = false}
                function w:start() self.running = true; return self end
                watchers[#watchers + 1] = w
                return w
            end,
        },
    },
    screen = {allScreens = function() return screens end},
    host = {idleTime = function() return idle end},
    timer = {
        doAfter = function(delay, fn) return Timer(delay, fn, false) end,
        doEvery = function(delay, fn) return Timer(delay, fn, true) end,
    },
    eventtap = {
        event = {
            types = {
                keyDown = 10, flagsChanged = 12, mouseMoved = 5,
                leftMouseDown = 1, rightMouseDown = 3, otherMouseDown = 25,
                scrollWheel = 22, systemDefined = 14,
            },
        },
        new = function(types, fn)
            local t = {types = types, fn = fn, running = false}
            function t:start() self.running = true; return self end
            function t:stop() self.running = false; return self end
            taps[#taps + 1] = t
            return t
        end,
    },
    urlevent = {bind = function(_, fn) urlHandler = fn end},
}

local here = debug.getinfo(1, 'S').source:match('^@(.*[/\\])') or './'

-- existingShutdown models another module having claimed hs.shutdownCallback
-- before this one loads; it has to be in place *before* the dofile, since that
-- is when the module captures what it must chain.
local function load(withScreens, caffeinated, existingShutdown, startIdle)
    reset()
    screens = withScreens
    idle = startIdle or 0 -- reset() zeroes it; a reload can land on any value
    assertions.displayIdle = caffeinated or false
    hs.shutdownCallback = existingShutdown
    caffeineDim = nil
    package.loaded['caffeinate'] = nil
    dofile(here .. '../caffeinate.lua')
end

-- The one timer still scheduled, i.e. the watch loop's next wake-up
local function pending()
    for i = #timers, 1, -1 do
        if timers[i].running and not timers[i].repeating then return timers[i] end
    end
end

local function fire(timer)
    if timer then timer.fn() end
end

-- The live eventtap, if the screen is dimmed
local function liveTap()
    for i = #taps, 1, -1 do
        if taps[i].running then return taps[i] end
    end
end

-- Run the fade timer to completion, however many steps FADE_TIME asks for. The
-- bound is only there so a module that never stops its fade fails the run
-- instead of hanging it.
local function runFade()
    for _, t in ipairs(timers) do
        if t.repeating and t.running then
            for _ = 1, 1000 do
                if not t.running then break end
                t.fn()
            end
        end
    end
end

local function levels()
    local out = {}
    for _, s in ipairs(screens) do out[#out + 1] = string.format('%.4f', s.level) end
    return table.concat(out, ' ')
end

local function BUILTIN() return Screen('Built-in Retina Display', 0.4045) end

-- The thresholds are locals of the module, so they are read back from its
-- behaviour rather than repeated here: loading it caffeinated with a clean idle
-- arms exactly one timer, and that delay is DIM_AFTER. Tuning the constant in
-- caffeinate.lua then moves this suite with it instead of breaking it -- it was
-- 30 s when this was written and 60 s a day later.
load({BUILTIN()}, true)
local DIM_AFTER = pending() and pending().delay
if type(DIM_AFTER) ~= 'number' then
    error('the module armed no watch on a caffeinated load -- nothing below can hold')
end
local DIM_POLL = 2 -- mirrors the module; a short poll, not a full delay
print(string.format('-- read from the module: DIM_AFTER=%s --\n', tostring(DIM_AFTER)))


-- Nothing happens while the assertion is not held -----------------------------

load({BUILTIN()}, false)
check('menubar without caffeine', menu.title, '💤')
check('no watch scheduled when off', pending(), nil)

idle = 3600
fire(pending())
check('a long idle changes nothing when off', levels(), '0.4045')


-- Turning it on starts the watch ----------------------------------------------

load({BUILTIN()}, true)
check('menubar with caffeine', menu.title, '☕️')
check('watch armed on load', pending() and pending().delay, DIM_AFTER)

-- Below the threshold it reschedules for exactly the remainder, rather than
-- polling every second
idle = 5
fire(pending())
check('reschedules for the remainder', pending() and pending().delay, DIM_AFTER - 5)
check('nothing dimmed below the threshold', levels(), '0.4045')
check('no eventtap while undimmed', liveTap(), nil)


-- Crossing the threshold -------------------------------------------------------

idle = DIM_AFTER
fire(pending())
check('an eventtap goes up with the dim', liveTap() ~= nil, true)
check('backstop poll while dimmed', pending() and pending().delay, DIM_POLL)
runFade()
check('faded down to DIM_LEVEL', levels(), '0.0500')


-- Waking on input --------------------------------------------------------------

local tap = liveTap()
local swallowed = tap.fn()
check('the waking event is not swallowed', swallowed, false)
check('restored exactly, no drift', levels(), '0.4045')
check('the eventtap is stopped again', liveTap(), nil)
check('the watch is re-armed for a full delay', pending() and pending().delay, DIM_AFTER)


-- The backstop, for when macOS disables the tap behind our back -----------------

idle = DIM_AFTER
fire(pending())
runFade()
check('dimmed again', levels(), '0.0500')
liveTap():stop() -- macOS killing the tap; nothing tells us
idle = 1
fire(pending())
check('the poll restores without the tap', levels(), '0.4045')


-- Dropping the assertion while dimmed --------------------------------------------

idle = DIM_AFTER
fire(pending())
runFade()
check('dimmed before the toggle', levels(), '0.0500')
clickCallback()
check('menubar after the toggle', menu.title, '💤')
check('turning caffeine off restores', levels(), '0.4045')
check('and stops the watch', pending(), nil)

-- ...and the same through the URL handler, which is the terminal's path
load({BUILTIN()}, true)
idle = DIM_AFTER
fire(pending())
runFade()
urlHandler(nil, {action = 'off'})
check('caffeine off by url restores', levels(), '0.4045')
check('url off stops the watch', pending(), nil)
idle = 0
urlHandler(nil, {action = 'on'})
check('url on re-arms the watch', pending() and pending().delay, DIM_AFTER)


-- Idle already on the clock when the assertion goes up ----------------------------
--
-- Nothing guarantees the assertion is turned on by a hand that just touched
-- something: a reload, or anything reaching the url event, arrives with idle
-- time already accrued. Arming a full delay there restarts a countdown that was
-- most of the way done. Traced on the live module before this was fixed: idle
-- ran from 30 to 41 s with the screen still at full brightness (the threshold
-- was 30 s that day).

-- fractions of the threshold rather than fixed seconds, so the suite holds
-- whatever caffeinate.lua is tuned to
local PART_WAY = math.floor(DIM_AFTER / 3)
load({BUILTIN()}, false)
idle = PART_WAY
urlHandler(nil, {action = 'on'})
check('an already-idle start counts what is left', pending() and pending().delay, DIM_AFTER - PART_WAY)
check('and does not dim yet', levels(), '0.4045')

load({BUILTIN()}, false)
idle = DIM_AFTER + 15
urlHandler(nil, {action = 'on'})
runFade()
check('past the threshold it dims at once', levels(), '0.0500')
check('and drops to the backstop poll', pending() and pending().delay, DIM_POLL)

-- the same on a reload, where the assertion outlives the Lua state watching it
load({BUILTIN()}, true)
check('a reload with a fresh idle arms the full delay', pending() and pending().delay, DIM_AFTER)
local HALF_WAY = math.floor(DIM_AFTER / 2)
load({BUILTIN()}, true, nil, HALF_WAY)
check('a reload mid-countdown resumes it', pending() and pending().delay, DIM_AFTER - HALF_WAY)
load({BUILTIN()}, true, nil, DIM_AFTER + 15)
runFade()
check('a reload while long idle dims at once', levels(), '0.0500')


-- Nothing may persist the dim level -----------------------------------------------

local function dimThen(event)
    load({BUILTIN()}, true)
    idle = DIM_AFTER
    fire(pending())
    runFade()
    watchers[1].fn(event)
    return levels()
end

local w = hs.caffeinate.watcher
check('sleeping undims first', dimThen(w.systemWillSleep), '0.4045')
check('the screens sleeping undims', dimThen(w.screensDidSleep), '0.4045')
check('locking undims', dimThen(w.screensDidLock), '0.4045')
check('powering off undims', dimThen(w.systemWillPowerOff), '0.4045')

load({BUILTIN()}, true)
idle = DIM_AFTER
fire(pending())
runFade()
hs.shutdownCallback()
check('a reload undims', levels(), '0.4045')

-- hs.shutdownCallback is a single slot, so the module must chain what it found
-- rather than assign over it -- and still undim on the way through
local ran = false
load({BUILTIN()}, true, function() ran = true end)
idle = DIM_AFTER
fire(pending())
runFade()
hs.shutdownCallback()
check('an existing shutdown callback still runs', ran, true)
check('and the chained reload still undims', levels(), '0.4045')


-- Screens the API cannot speak for --------------------------------------------------

load({Screen('LG HDR 4K', 0.8, {supported = false})}, true)
idle = DIM_AFTER
fire(pending())
runFade()
check('a display answering -1 is left alone', levels(), '0.8000')
check('and no fade was started for it', screens[1].sets, 0)

load({Screen('Broken', 0.8, {errors = true})}, true)
idle = DIM_AFTER
fire(pending())
runFade()
check('a display that throws is skipped', levels(), '0.8000')

-- A screen already darker than DIM_LEVEL must not be *raised* by the dim
load({BUILTIN(), Screen('Already dark', 0.02)}, true)
idle = DIM_AFTER
fire(pending())
runFade()
check('a darker screen is not raised', levels(), '0.0500 0.0200')
liveTap().fn()
check('both restored exactly', levels(), '0.4045 0.0200')

-- Two dimmable screens are both driven, each back to its own level
load({BUILTIN(), Screen('LG HDR 4K', 0.75)}, true)
idle = DIM_AFTER
fire(pending())
runFade()
check('both screens dim', levels(), '0.0500 0.0500')
liveTap().fn()
check('each returns to its own level', levels(), '0.4045 0.7500')


-- Waking mid-fade -----------------------------------------------------------------

load({BUILTIN()}, true)
idle = DIM_AFTER
fire(pending())
for _, t in ipairs(timers) do -- three steps only, a fifth of the way down
    if t.repeating and t.running then t.fn(); t.fn(); t.fn() end
end
check('mid-fade the screen is on its way down', screens[1].level < 0.4045, true)
liveTap().fn()
check('waking mid-fade lands exactly on the start', levels(), '0.4045')
runFade() -- a fade left running would keep pulling it down
check('the fade was cancelled, not just ignored', levels(), '0.4045')


print(failed == 0 and '\nALL PASS' or ('\n' .. failed .. ' FAILURE(S)'))
os.exit(failed == 0 and 0 or 1)
