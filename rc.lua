-- =====================================================
-- COMPLETE RC.LUA FOR AWESOMEWM
-- =====================================================

-- ===========================
-- IMPORTS
-- ===========================
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

-- ===========================
-- TERMINAL, MODKEY AND THEME
-- ===========================
local terminal = "kitty"
local modkey = "Mod4"

beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/catppuccin/theme.lua")

-- ===========================
-- WALLPAPER
-- ===========================
local wallpaper_dir = os.getenv("HOME") .. "/.config/awesome/themes/wallpapers/"
beautiful.wallpaper = wallpaper_dir .. "japan_landscape.jpg"

screen.connect_signal("request::wallpaper", function(s)
    if beautiful.wallpaper then
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end)

-- Random wallpaper change every 10 minutes
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

-- ===========================
-- BORDERS AND GAPS
-- ===========================
beautiful.border_width      = dpi(0)
beautiful.border_focus      = "#CCCCCC"
beautiful.border_normal     = "#555555"
beautiful.useless_gap       = dpi(0)
beautiful.gap_single_client = true

-- ===========================
-- LAUNCH POLYBAR
-- ===========================
awful.spawn.with_shell("~/.config/polybar/launch.sh")

-- ===========================
-- CUSTOM TILE LAYOUT
-- ===========================
local custom_tile = {}
custom_tile.name = "custom_tile"

function custom_tile.arrange(p)
    local wa, cls = p.workarea, p.clients
    if #cls == 0 then return end

    local internal_gap = dpi(12)
    local outer_gap    = dpi(12)
    local top_left_offset = dpi(4)
    local max_cols = 3
    local total_rows = math.ceil(#cls / max_cols)
    local row_counts = {}

    local i = 1
    for row = 1, total_rows do
        local remaining = #cls - (i - 1)
        row_counts[row] = math.min(max_cols, remaining)
        i = i + row_counts[row]
    end

    local idx = 1
    local y = wa.y + outer_gap - top_left_offset
    local avail_height = wa.height - outer_gap * 2 - internal_gap * (total_rows - 1) + top_left_offset
    local row_height = avail_height / total_rows

    for row = 1, total_rows do
        local cols_in_row = row_counts[row]
        local avail_width = wa.width - outer_gap * 2 - internal_gap * (cols_in_row - 1) + top_left_offset
        local cell_width = avail_width / cols_in_row
        local start_x = wa.x + outer_gap - top_left_offset

        if cols_in_row < max_cols then
            local used_width = cell_width * cols_in_row + internal_gap * (cols_in_row - 1)
            start_x = start_x + (wa.width - outer_gap * 2 - used_width + top_left_offset) / 2
        end

        for col = 0, cols_in_row - 1 do
            local c = cls[idx]
            if c then
                c:geometry({
                    x = start_x + col * (cell_width + internal_gap),
                    y = y,
                    width = cell_width,
                    height = row_height
                })
            end
            idx = idx + 1
        end

        y = y + row_height + internal_gap
    end
end

awful.layout.layouts = { custom_tile }

-- ===========================
-- TAGS
-- ===========================
awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1","2","3","4","5" }, s, awful.layout.layouts[1])
end)

-- ===========================
-- CLIENT SIGNALS
-- ===========================
client.connect_signal("manage", function(c)
    if c.class == "Polybar" then
        c.floating, c.ontop, c.above, c.skip_taskbar, c.sticky, c.border_width = true, true, true, true, true, 0
        return
    end

    awful.client.setslave(c)

    if not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus", function(c)
    if c.class ~= "Polybar" then c.border_color = beautiful.border_focus end
end)

client.connect_signal("unfocus", function(c)
    if c.class ~= "Polybar" then c.border_color = beautiful.border_normal end
end)

-- ===========================
-- KEYBINDINGS
-- ===========================
globalkeys = gears.table.join(
    -- Launchers
    awful.key({modkey}, "Return", function() awful.spawn(terminal) end, {description="open terminal", group="launcher"}),
    awful.key({modkey}, "b", function() awful.spawn("firefox") end, {description="open firefox", group="launcher"}),
    awful.key({modkey}, "d", function() 
        awful.spawn("bash " .. os.getenv("HOME") .. "/.config/rofi/launchers/type-3/launcher.sh") 
    end, {description = "abrir Rofi type-3", group="launcher"}),

    -- Client focus
    awful.key({modkey}, "j", function() awful.client.focus.byidx(1) end, {description="focus next", group="client"}),
    awful.key({modkey}, "k", function() awful.client.focus.byidx(-1) end, {description="focus previous", group="client"}),
    awful.key({modkey}, "q", function() if client.focus then client.focus:kill() end end, {description="close client", group="client"}),

    -- Awesome control
    awful.key({modkey, "Control"}, "r", awesome.restart, {description="reload awesome", group="awesome"}),
    awful.key({modkey, "Shift"}, "l", function() awesome.quit() end, {description="quit awesome", group="awesome"}),

    -- Maximize client
    awful.key({modkey}, "f", function()
        local c = client.focus
        if c then
            c.maximized = not c.maximized
            c:raise()
        end
    end, {description = "toggle maximized", group="client"}),

    -- ===========================
    -- VOLUME CONTROL (SUPER + F7/F8/F9)
    -- ===========================
    awful.key({modkey}, "F9", function()
        awful.spawn.with_shell([[
            current=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
            new=$((current + 5))
            if [ $new -gt 100 ]; then new=100; fi
            pactl set-sink-volume @DEFAULT_SINK@ ${new}%
        ]])
    end, {description = "subir volumen", group = "media"}),

    awful.key({modkey}, "F8", function()
        awful.spawn.with_shell([[
            current=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1 | tr -d '%')
            new=$((current - 5))
            if [ $new -lt 0 ]; then new=0; fi
            pactl set-sink-volume @DEFAULT_SINK@ ${new}%
        ]])
    end, {description = "bajar volumen", group = "media"}),

    awful.key({modkey}, "F7", function()
        awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
    end, {description = "mute", group = "media"})
)

-- ===========================
-- TAG SWITCHING KEYS
-- ===========================
for i = 1,5 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({modkey}, "#" .. i + 9, function()
            local s = awful.screen.focused()
            local tag = s.tags[i]
            if tag then tag:view_only() end
        end, {description = "view tag #" .. i, group="tag"})
    )
end

-- ===========================
-- SWAP FULL-SIZE WINDOWS
-- ===========================
local function swap_full(dir)
    local c = client.focus
    if not c then return end

    local target
    if dir == "right" then
        target = awful.client.next(1)
    elseif dir == "left" then
        target = awful.client.next(-1)
    end

    if not target then return end

    local geo_c = c:geometry()
    local geo_t = target:geometry()

    c:geometry(geo_t)
    target:geometry(geo_c)

    c:swap(target)
end

globalkeys = gears.table.join(globalkeys,
    awful.key({modkey, "Shift"}, "Right", function() swap_full("right") end, {description = "swap full-size with next window", group = "client"}),
    awful.key({modkey, "Shift"}, "Left", function() swap_full("left") end, {description = "swap full-size with previous window", group = "client"})
)

root.keys(globalkeys)

-- ===========================
-- MOUSE BINDINGS
-- ===========================
clientbuttons = gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate","mouse_click",{raise=true}) end),
    awful.button({modkey},1,function(c) c:activate{context="mouse_click",action="mouse_move"} end),
    awful.button({modkey},3,function(c) c:activate{context="mouse_click",action="mouse_resize"} end)
)

-- ===========================
-- RULES
-- ===========================
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

