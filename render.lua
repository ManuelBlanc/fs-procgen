-- Draw dungeons as ASCII, optionally using term colors.

local isatty = require("platform").isatty
local concat, format = table.concat, string.format

-- Select Graphic Rendition
local function SGR_color(a, s) return format("\27[%sm%s\27[0m", a, s) end
local function SGR_plain(_, s) return s end

-- Upvalues used for buffering lines. This is a bit faster than writing individual characters.
local _buf, _n = {}

--- Renders a grid into a file with the given options.
-- @arg grid        The grid that is being drawn.
-- @arg palette     A thunk that maps grid elements to characters. Receives: (v, x, y, SGR, ctx)
-- @arg ctx         A context for the palette function. Can be any Lua value.
-- @arg out         The output file stream. Default: stdout.
-- @arg color       A flag to force color output. Default: true if out is a tty, false otherwise.
local function render_draw(grid, palette, ctx, out, use_color)
    out = out or io.stdout
    local SGR = SGR_plain
    if use_color == nil then
        use_color = isatty(out)
    end
    if use_color then
        SGR = SGR_color
        out:write("\27[2J\27[1;1H")
    end
    for y=0, grid.h-1 do
        _n = 1
        for x=0, grid.w-1 do
            _buf[_n], _n = palette(grid:get(x, y), x, y, SGR, ctx), _n+1
        end
        _buf[_n] = "\n"
        out:write(concat(_buf, "", 1, _n))
    end
end

return {
    draw = render_draw,
}
