-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
require("awful.autofocus")
-- Theme handling library
local beautiful = require("beautiful")

local error_checking = require("utils.error-checking")
error_checking:init({})

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.init(gears.filesystem.get_configuration_dir() .. "themes/multicolor/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "wezterm"
editor = os.getenv("EDITOR") or "nvim"
editor_cmd = terminal .. " -e " .. editor
fileManager = "ranger"
calculator = "octave"
modkey = "Mod4"

local screen_config = require("screen")
screen_config:init({})

local menu = require("menu")
menu:init({})

local keymap = require("keymap")
keymap:init({terminal = terminal, mymainmenu = menu.mymainmenu, fileManager = fileManager, calculator = calculator})

local rules = require("rules")
rules:init({clientkeys = keymap.clientkeys, clientbuttons = keymap.clientbuttons})

local signals = require("signals")
signals:init({})
