--[[ grid.lua -- A 2D matrix implementation.
It's backed by a 1D VLA that stores ints.
]]

-- local ffi = require("ffi")
-- ffi.cdef[[ struct Grid { int w, h, va[?]; }; ]]
-- local _Grid_ctype = ffi.typeof("struct Grid")

local function grid_init(gr, w, h, v0)
    gr.w, gr.h = w, h
    for i=0, w*h-1 do gr[i] = v0 end
end

local function grid_get(gr, x, y)
    if x < 0 or x >= gr.w or y < 0 or y >= gr.h then return 0 end
    return gr[x + y*gr.w]
end

local function grid_set(gr, x, y, v)
    gr[x + y*gr.w] = v
end

--   1
-- 4 * 2
--   3
local function grid_neigh4(gr, x, y)
    return grid_get(gr, x, y-1), grid_get(gr, x+1, y),
           grid_get(gr, x, y+1), grid_get(gr, x-1, y)
end

-- 8 1 2
-- 7 * 3
-- 6 5 4
local function grid_neigh8(gr, x, y)
    return grid_get(gr, x,   y-1), grid_get(gr, x+1, y-1),
           grid_get(gr, x+1, y  ), grid_get(gr, x+1, y+1),
           grid_get(gr, x,   y+1), grid_get(gr, x-1, y+1),
           grid_get(gr, x-1, y  ), grid_get(gr, x-1, y-1)
end

local function grid_each(gr, thunk)
    local i = 0
    for y=0, gr.h do
        for x=0, gr.w do
            thunk(gr[i], x, y)
            i = i + 1
        end
    end
end

local function grid_map(gr, thunk)
    local i = 0
    for y=0, gr.h do
        for x=0, gr.w do
            gr[i] = thunk(gr[i], x, y)
            i = i + 1
        end
    end
end

return {
    init    = grid_init,
    get     = grid_get,
    set     = grid_set,
    neigh4  = grid_neigh4,
    neigh8  = grid_neigh8,
    each    = grid_each,
    map     = grid_map,
}
