-- Caffeinate
local caffeine = hs.menubar.new()
local function setCaffeineDisplay(state)
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
