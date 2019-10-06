--[[ architect.lua -- Level generator. ]]

local ffi = require("ffi")
ffi.cdef[[ struct AABB { int x0, y0, x1, y1; }; ]]
local AABB = ffi.typeof("struct AABB")
ffi.metatype(AABB, {
    __tostring = function(A)
        return string.format("AABB(%i, %i, %i, %i)", A.x0, A.y0, A.x1, A.y1)
    end,
})
local function AABB_intersects(A, B)
    return A.x0 <= B.x1 and A.x1 >= B.x0 and A.y0 <= B.y1 and A.y1 >= B.y0
end
local function AABB_contains(A, B)
    return A.x0 <= B.x0 and A.x1 >= B.x1 and A.y0 <= B.y0 and A.y1 >= B.y1
end

local function arch_init(arch, grid, rng)
    arch.grid = grid
    arch.w, arch.h = grid.w, grid.h
    arch.rng = rng
    arch.span = AABB(0, 0, grid.w-1, grid.h-1)
end

local function arch_is_valid(arch, room)
    if not AABB_contains(arch.span, room) then return false end
    for i=1, #arch do
        if AABB_intersects(room, arch[i]) then return false end
    end
    return true
end

local function arch_carve(arch, room)
    local grid = arch.grid
    local x0, y0, x1, y1 = room.x0, room.y0, room.x1, room.y1
    for x=x0+1, x1-1 do
        for y=y0+1, y1-1 do
            grid:set(x, y, 1)
        end
    end
    for x=x0, x1, x0<=x1 and 1 or -1 do grid:set(x, y0, 2) grid:set(x, y1, 2) end
    for y=y0, y1, y0<=y1 and 1 or -1 do grid:set(x0, y, 2) grid:set(x1, y, 2) end
    arch[#arch+1] = room
    return room
end

local function arch_line_xy(arch, x0, y0, x1, y1)
    local grid = arch.grid
    for x=x0, x1, x0<=x1 and 1 or -1 do grid:set(x, y0, 1) end
    for y=y0, y1, y0<=y1 and 1 or -1 do grid:set(x1, y, 1) end
end

local function arch_line_yx(arch, x0, y0, x1, y1)
    return arch_line_xy(arch, x1, y1, x0, y0)
end


local function arch_room0(arch, hW, hH)
    local cx, cy = math.floor(arch.w/2), math.floor(arch.h/2)
    return arch_carve(arch, AABB(cx-hW, cy-hH, cx+hW, cy+hH))
end

local function arch_grow(arch, room, w, h, pad)
    local rng, leaf, w1, h1 = arch.rng, AABB(), w, h
    if not pad then pad = 1 end
    for tries=1, 20 do
        ::retry::
        local d = rng:next_range(4)
        local dx = rng:next_range(room.x0-w1, room.x1)
        local dy = rng:next_range(room.y0-h1, room.y1)
        if d == 1 then
            leaf.x0, leaf.y1 = dx, room.y0-pad
            leaf.x1, leaf.y0 = dx+w1, leaf.y1-h1
        elseif d == 2 then
            leaf.x0, leaf.y0 = room.x1+pad, dy
            leaf.x1, leaf.y1 = leaf.x0+w1, dy+h1
        elseif d == 3 then
            leaf.x0, leaf.y0 = dx, room.y1+pad
            leaf.x1, leaf.y1 = dx+w1, leaf.y0+h1
        else-- d == 4
            leaf.x1, leaf.y0 = room.x0-pad, dy
            leaf.x0, leaf.y1 = leaf.x1-w1, dy+h1
        end
        if arch_is_valid(arch, leaf) then
            --arch_line_xy(arch, leaf.x0, leaf.y1, room.x1, room.x0)
            return arch_carve(arch, leaf)
        end
    end
end

local ceil, max = math.ceil, math.max
local function arch_rand_room(arch)
    local rng, n = arch.rng, #arch
    assert(n > 0)
    local room = arch[rng:next_range(n)]
    local w = max(4, ceil(rng:next_normal(12, 2)))
    local h = max(4, ceil(rng:next_normal(5, 2)))
    return arch_grow(arch, room, w, h, 1)
end

local floor = math.floor
local function arch_line(arch, x0, y0, x1, y1)
    local grid = arch.grid
    if x0 ~= x1 then
        local ss, y = (y1 - y0) / (x1 - x0), y0
        for x=x0, x1, x0<=x1 and 1 or -1 do
            grid:set(x, floor(y+0.5), 1)
            local fy = floor(y + ss + 0.5)
            if fy > y then grid:set(x, fy, 1) end
            y = y + ss
        end
    else
        for y=y0, y1 do grid:set(x0, y0, 1) end
    end
end

return {
    init = arch_init,
    carve = arch_carve,
    room0 = arch_room0,
    grow = arch_grow,
    rand_room = arch_rand_room,
    line = arch_line,
}
