local awful    = require("awful")
local naughty  = require("naughty")
local wibox    = require("wibox")
local timer    = require("gears.timer")
local math     = math
local string   = string
local type     = type
local tonumber = tonumber

local function factory(args)
    local pulsebar = {
        colors = {
            background      = "#000000",
            mute_background = "#000000",
            mute            = "#EB8F8F",
            unmute          = "#A4CE8A"
        },

        _current_level = 0,
        _mute          = false,
        device         = "N/A"
    }

    args             = args or {}

    local timeout    = args.timeout or 5
    local settings   = args.settings or function() end
    local width      = args.width or 63
    local height     = args.height or 1
    local margins    = args.margins or 1
    local paddings   = args.paddings or 1
    local ticks      = args.ticks or false
    local ticks_size = args.ticks_size or 7
    local tick       = args.tick or "|"
    local tick_pre   = args.tick_pre or "["
    local tick_post  = args.tick_post or "]"
    local tick_none  = args.tick_none or " "

    pulsebar.colors              = args.colors or pulsebar.colors
    pulsebar.followtag           = args.followtag or false
    pulsebar.notification_preset = args.notification_preset

    if not pulsebar.notification_preset then
        pulsebar.notification_preset = {
            font = "Monospace 10"
        }
    end

    pulsebar.bar = wibox.widget {
        color            = pulsebar.colors.unmute,
        background_color = pulsebar.colors.background,
        forced_height    = height,
        forced_width     = width,
        margins          = margins,
        paddings         = paddings,
        ticks            = ticks,
        ticks_size       = ticks_size,
        widget           = wibox.widget.progressbar,
    }

    pulsebar.tooltip = awful.tooltip({ objects = { pulsebar.bar } })

    --- HELPER FUNCTIONS

    -- run a command and execute a function on its output (asynchronous pipe)
    -- @param cmd the input command
    -- @param callback function to execute on cmd output
    -- @return cmd PID
    function pulsebar.async(cmd, callback)
        return awful.spawn.easy_async(cmd,
	function (stdout, _, _, exit_code)
	callback(stdout, exit_code)
        end)
    end

    pulsebar.timer_table = {}

    function pulsebar.newtimer(name, timeout, fun, nostart, stoppable)
        if not name or #name == 0 then return end
        name = (stoppable and name) or timeout
        if not pulsebar.timer_table[name] then
            pulsebar.timer_table[name] = timer({ timeout = timeout })
            pulsebar.timer_table[name]:start()
        end
        pulsebar.timer_table[name]:connect_signal("timeout", fun)
        if not nostart then
            pulsebar.timer_table[name]:emit_signal("timeout")
        end
        return stoppable and pulsebar.timer_table[name]
    end

    --- FUNTIONALITY

    function pulsebar.update(callback)
        pulsebar.async({ awful.util.shell, "-c", "pamixer --get-volume" },
        function(s)
            local volume = s

            if volume ~= pulsebar._current_level then
                pulsebar._current_level = tonumber(volume)
                pulsebar.bar:set_value(pulsebar._current_level / 100)
	        pulsebar.tooltip:set_text(string.format("Volume: %d%%", volume))
	        pulsebar.bar.color = pulsebar.colors.unmute
	        pulsebar.bar.background_color = pulsebar.colors.background

                settings()

                if type(callback) == "function" then callback() end
            end
        end)
        pulsebar.async({ awful.util.shell, "-c", "pamixer --get-mute" },
        function(s)
	    stringtoboolean = { ["true"]=true, ["false"]=false }
            local mute = stringtoboolean[s]

            if mute ~= pulsebar._mute then
                if mute == true then
                    pulsebar._mute = mute
                    pulsebar.tooltip:set_text ("[muted]")
                    pulsebar.bar.color = pulsebar.colors.mute
                    pulsebar.bar.background_color = pulsebar.colors.mute_background
                else
                    pulsebar._mute = "no"
                end

                settings()

                if type(callback) == "function" then callback() end
            end
        end)
    end

    function pulsebar.increasevol()
        pulsebar.async({ awful.util.shell, "-c", "pamixer -i 1" },
	function(s)
	     pulsebar.notify()
	end)
    end

    function pulsebar.decreasevol()
        pulsebar.async({ awful.util.shell, "-c", "pamixer -d 1" },
	function(s)
	     pulsebar.notify()
	end)
    end

    function pulsebar.notify()
        pulsebar.update(function()
            local preset = pulsebar.notification_preset

            preset.title = string.format("Volume: %s%%", pulsebar._current_level)

            if pulsebar._mute == true then
                preset.title = preset.title .. " muted"
            end

            -- tot is the maximum number of ticks to display in the notification
            -- fallback: default horizontal wibox height
            local wib, tot = awful.screen.focused().mywibox, 20

            -- if we can grab mywibox, tot is defined as its height if
            -- horizontal, or width otherwise
            if wib then
                if wib.position == "left" or wib.position == "right" then
                    tot = wib.width
                else
                    tot = wib.height
                end
            end

            local int = math.modf((pulsebar._current_level / 100) * tot)
            preset.text = string.format(
                "%s%s%s%s",
                tick_pre,
                string.rep(tick, int),
                string.rep(tick_none, tot - int),
                tick_post
            )

            if pulsebar.followtag then preset.screen = awful.screen.focused() end

            if not pulsebar.notification then
                pulsebar.notification = naughty.notify {
                    preset  = preset,
                    destroy = function() pulsebar.notification = nil end
                }
            else
                naughty.replace_text(pulsebar.notification, preset.title, preset.text)
            end
        end)
    end

    pulsebar.newtimer("Pulsebar", timeout, pulsebar.update)

    return pulsebar
end

return factory
