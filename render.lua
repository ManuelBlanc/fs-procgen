--[[ render.lua -- Draw dungeons as ASCII, optionally using term colors. ]]

local ffi = require("ffi")
ffi.cdef[[ int isatty(int fd); ]]

local function SGR_color(a, s) return string.format("\27[%sm%s\27[0m", a, s) end
local function SGR_plain(_, s) return s end
local SGR

local function render_set_color(bool)
    if bool then SGR = SGR_color else SGR = SGR_plain end
end

render_set_color(ffi.C.isatty(1) == 1)

local _buf, _n = {}
local function render_draw(grid, palette, ctx, out)
    out = out or io.stdout
    if SGR == SGR_color then out:write("\27[2J\27[1;1H") end
    for y=0, grid.h-1 do
        _n = 1
        for x=0, grid.w-1 do
            _buf[_n], _n = palette(grid:get(x, y), x, y, SGR, ctx), _n+1
        end
        _buf[_n] = "\n"
        out:write(table.concat(_buf, "", 1, _n)) -- Bit faster.
    end
end

return {
    draw = render_draw,
    set_color = render_set_color,
}
