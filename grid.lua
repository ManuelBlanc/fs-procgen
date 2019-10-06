--[[ grid.lua -- A 2D array implementation.
It

It's implemented as a list.
]]

local ffi = require("ffi")
ffi.cdef[[
    struct grid {
        int w, h;
        int data[?];
    };
]]

local function grid_init(gr, w, h, v0)
    gr.w, gr.h, gr.v0 = w, h, v0
    for i=0, w*h-1 do
        gr[i] = v0
    end
    return gr
end

local function grid_get(gr, x, y)
    if x < 0 or x >= gr.w or y < 0 or y >= gr.h then return gr.v0 end
    return gr[x + y*gr.w]
end

local function grid_set(gr, x, y, v)
    gr[x + y*gr.w] = v
end

local function grid_neigh4(gr, x, y)
    return grid_get(gr, x, y-1), grid_get(gr, x+1, y),
           grid_get(gr, x, y+1), grid_get(gr, x-1, y)
end

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
}
