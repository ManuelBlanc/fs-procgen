--[[ render.lua -- Draw dungeons as ASCII, optionally using term colors. ]]

local isatty = require("platform").isatty

local function SGR_color(a, s) return string.format("\27[%sm%s\27[0m", a, s) end
local function SGR_plain(_, s) return s end

-- Buffering lines is a bit faster than outputting individual characters.
local _buf, _n = {}
local function render_draw(grid, palette, ctx, out, color)
    out = out or io.stdout
    local SGR = SGR_plain
    if color == nil then
        color = isatty(out)
    end
    if color then
        SGR = SGR_color
        out:write("\27[2J\27[1;1H")
    end
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
}
