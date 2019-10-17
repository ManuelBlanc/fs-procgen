--- A 2D matrix implementation, backed on a 1D array.

-- local ffi = require("ffi")
-- ffi.cdef[[ struct Grid { int w, h, va[?]; }; ]]
-- local _Grid_ctype = ffi.typeof("struct Grid")

--- Initialize a new grid.
local function grid_init(gr, w, h, v0)
    gr.w, gr.h = w, h
    for i=0, w*h-1 do gr[i] = v0 end
end

--- Retrieve the value of a cell at a given coordinate.
local function grid_get(gr, x, y)
    if x < 0 or x >= gr.w or y < 0 or y >= gr.h then return 0 end
    return gr[x + y*gr.w]
end

--- Modify the cell at a given coordinate.
local function grid_set(gr, x, y, v)
    assert(x >= 0 and x < gr.w and y >= 0 and y < gr.h)
    gr[x + y*gr.w] = v
end

--- Retrieve the 4 orthogonal neighbours.
local function grid_neigh4(gr, x, y)
    return                       grid_get(gr, x, y-1),                          --   1
           grid_get(gr, x-1, y),                       grid_get(gr, x+1, y),    -- 2 * 3
                                 grid_get(gr, x, y+1)                           --   4
end

--- Retrieve the 4 orthogonal + 4 diagonal neighbours.
local function grid_neigh8(gr, x, y)
    return grid_get(gr, x-1, y-1), grid_get(gr, x, y-1), grid_get(gr, x+1, y-1),    -- 1 2 3
           grid_get(gr, x-1, y),                         grid_get(gr, x+1, y),      -- 4 * 5
           grid_get(gr, x-1, y+1), grid_get(gr, x, y+1), grid_get(gr, x+1, y+1)     -- 6 7 8
end

--- Execute a thunk for each cell in the grid.
local function grid_each(gr, thunk)
    local i = 0
    for y=0, gr.h do
        for x=0, gr.w do
            thunk(gr[i], x, y)
            i = i + 1
        end
    end
end

--- Map each cell in the grid using a thunk.
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
