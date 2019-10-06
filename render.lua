--[[ render.lua -- Draw dungeons as ASCII, optionally using term colours. ]]

local ffi = require("ffi")
ffi.cdef[[ int isatty(int fd); ]]

local SGR
local function render_set_colour(bool)
    if bool then
        SGR = function(a, s) return string.format("\27[%sm%s\27[0m", a, s) end
    else
        SGR = function(_, s) return s end
    end
end

render_set_colour(ffi.C.isatty(1) == 1)

local function render_draw(grid, palette, out)
    out = out or io.stdout
    out:write("# dungeon1.out\n")
    for y=0, grid.h-1 do
        for x=0, grid.w-1 do
            local v = grid:get(x, y)
            out:write(palette(v, x, y, SGR))
        end
        out:write("\n")
    end
end

return {
    draw = render_draw,
    set_colour = render_set_colour,
}
