-- Caffeinate
local caffeine = hs.menubar.new()
local function setCaffeineDisplay(state)
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
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

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
