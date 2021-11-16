local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")

local systray = function(s)

    local layout_buttons = {
        awful.button({ }, 1, function() awful.layout.inc( 1) end),
        awful.button({ }, 3, function() awful.layout.inc(-1) end),
    }

    local layoutbox = awful.widget.layoutbox {
        screen  = s,
        buttons = layout_buttons,
    }

    local layout_widget = container(
        wibox.container.margin(
            layoutbox,
            theme.margins,
            theme.margins,
            theme.margins,
            theme.margins
        )
    )

    return layout_widget
end

return systray
