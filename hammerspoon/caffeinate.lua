-- Caffeinate
local caffeine = hs.menubar.new()
function setCaffeineDisplay(state)
    if state then
        caffeine:setTitle("☕️")
        caffeine:setTooltip("Caffeinated!")
        -- caffeine:setIcon(os.getenv("HOME") .. "/.hammerspoon/assets/caffeine-on.pdf")
    else
        caffeine:setTitle("💤")
        caffeine:setTooltip("No caffeine :(")
        -- caffeine:setIcon(os.getenv("HOME") .. "/.hammerspoon/assets/caffeine-off.pdf")
    end
end

function caffeineClicked()
    setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
    caffeine:setClickCallback(caffeineClicked)
    setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end
