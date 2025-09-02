local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local naughty = require("naughty")

local terminal = "kitty"
local modkey = "Mod4"

-- Theme
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/catppuccin/theme.lua")

-- Wallpaper
local wallpaper_dir = os.getenv("HOME") .. "/.config/awesome/themes/wallpapers/"
beautiful.wallpaper = wallpaper_dir .. "japan_landscape.jpg"

-- Set wallpaper per screen
screen.connect_signal("request::wallpaper", function(s)
    if beautiful.wallpaper then
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end)

-- Timer for random wallpaper change every 10 minutes
local wallpapers = {}
for file in io.popen('ls "' .. wallpaper_dir .. '"'):lines() do
    table.insert(wallpapers, wallpaper_dir .. file)
end

gears.timer {
    timeout   = 600,
    autostart = true,
    call_now  = true,
    callback  = function()
        if #wallpapers == 0 then return end
        local wp = wallpapers[math.random(#wallpapers)]
        for s in screen do
            gears.wallpaper.maximized(wp, s, true)
        end
    end
}

-- Borders and gap
beautiful.border_width      = dpi(2)        -- Window border thickness
beautiful.border_focus      = "#CCCCCC"     -- Light gray for focused window
beautiful.border_normal     = "#555555"     -- Dark gray for unfocused window
beautiful.useless_gap       = dpi(2.5)      -- Gaps between windows
beautiful.gap_single_client = true

-- Launch Polybar
awful.spawn.with_shell("~/.config/polybar/launch.sh")

-- ===========================================
-- CUSTOM DYNAMIC 3-COLUMN LAYOUT
-- ===========================================
local custom_tile = {}
custom_tile.name = "custom_tile"

function custom_tile.arrange(p)
    local wa = p.workarea
    local cls = p.clients
    if #cls == 0 then return end

    local g = beautiful.useless_gap or 2.5
    local extra = dpi(3) -- extra gap for bottom and right
    local max_cols = 3
    local total_rows = math.ceil(#cls / max_cols)
    local y = wa.y + g
    local i = 1

    while i <= #cls do
        local remaining = #cls - i + 1
        local cols_in_row = math.min(max_cols, remaining)
        local row_index = math.ceil(i / max_cols) - 1

        -- Height per row excluding top+bottom gaps
        local row_height = (wa.height - g * (total_rows + 1)) / total_rows

        -- Width per window in this row
        local cw = (wa.width - g * (cols_in_row + 1)) / cols_in_row

        for j = 0, cols_in_row - 1 do
            local c = cls[i + j]
            if c then
                -- Adjust last column for right gap minus border width + extra
                local width = cw
                if j == cols_in_row - 1 then
                    width = wa.x + wa.width - g - (wa.x + g + j * (cw + g)) - beautiful.border_width - extra
                end

                -- Adjust last row for bottom gap minus border width + extra
                local height = row_height
                if row_index == total_rows - 1 then
                    height = wa.y + wa.height - g - y - beautiful.border_width - extra
                end

                c:geometry({
                    x = wa.x + g + j * (cw + g),
                    y = y,
                    width = width,
                    height = height
                })
            end
        end

        y = y + row_height + g
        i = i + cols_in_row
    end
end

-- Register layout
awful.layout.layouts = { custom_tile }

-- Tags
awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1","2","3","4","5" }, s, awful.layout.layouts[1])
end)

-- ===========================================
-- CLIENT SIGNALS
-- ===========================================
client.connect_signal("manage", function(c)
    if c.class == "Polybar" then
        c.floating = true
        c.ontop = true
        c.above = true
        c.skip_taskbar = true
        c.sticky = true
        c.border_width = 0
        return
    end

    awful.client.setslave(c)

    if not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus", function(c)
    if c.class ~= "Polybar" then
        c.border_color = beautiful.border_focus
    end
end)

client.connect_signal("unfocus", function(c)
    if c.class ~= "Polybar" then
        c.border_color = beautiful.border_normal
    end
end)

-- ===========================================
-- KEYBINDINGS
-- ===========================================
globalkeys = gears.table.join(
    awful.key({modkey}, "Return", function() awful.spawn(terminal) end),
    awful.key({modkey}, "b", function() awful.spawn("firefox") end),
    awful.key({modkey}, "d", function() awful.spawn("rofi -show drun") end),
    awful.key({modkey}, "j", function() awful.client.focus.byidx(1) end),
    awful.key({modkey}, "k", function() awful.client.focus.byidx(-1) end),
    awful.key({modkey}, "q", function() if client.focus then client.focus:kill() end end),
    awful.key({modkey, "Control"}, "r", awesome.restart),
    awful.key({modkey, "Shift"}, "l", function() awesome.quit() end)
)

for i = 1,5 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({modkey}, "#" .. i + 9, function()
            local s = awful.screen.focused()
            local tag = s.tags[i]
            if tag then tag:view_only() end
        end)
    )
end

root.keys(globalkeys)

-- ===========================================
-- MOUSE BINDINGS
-- ===========================================
clientbuttons = gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate","mouse_click",{raise=true}) end),
    awful.button({modkey},1,function(c) c:activate{context="mouse_click",action="mouse_move"} end),
    awful.button({modkey},3,function(c) c:activate{context="mouse_click",action="mouse_resize"} end)
)

-- ===========================================
-- RULES
-- ===========================================
awful.rules.rules = {
    {
        rule = {},
        properties = {
            floating = false,
            size_hints_honor = false,
            focus = true,
            raise = true,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
            border_width = dpi(2),
            border_color = beautiful.border_normal
        }
    }
}

