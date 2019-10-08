--[[ architect.lua -- Level generator. ]]


-- Axis aligned bounding box
local ffi = require("ffi")
ffi.cdef[[ struct AABB { int x0, y0, x1, y1; }; ]] -- Clopen set: [x0, x1) x [y0, y1)
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
local floor = math.floor
local function AABB_midpoint(A)
    return floor((A.x0 + A.x1)*0.5), floor((A.y0 + A.y1)*0.5)
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

local function arch_wall_if_not_floor(arch, x, y)
    local grid = arch.grid
    if grid:get(x, y) ~= 1 then grid:set(x, y, 2) end
end

local function arch_carve(arch, room)
    local grid = arch.grid
    local x0, y0, x1, y1 = room.x0, room.y0, room.x1, room.y1
    for x=x0+1, x1-1 do
        for y=y0+1, y1-1 do
            grid:set(x, y, 1)
        end
    end
    for x=x0, x1, x0<=x1 and 1 or -1 do
        arch_wall_if_not_floor(arch, x, y0)
        arch_wall_if_not_floor(arch, x, y1)
    end
    for y=y0, y1, y0<=y1 and 1 or -1 do
        arch_wall_if_not_floor(arch, x0, y)
        arch_wall_if_not_floor(arch, x1, y)
    end
    arch[#arch+1] = room
end

local function arch_step_line(arch, x0, y0, x1, y1)
    local grid = arch.grid
    for x=x0, x1, x0<=x1 and 1 or -1 do grid:set(x, y0, 1) end
    for y=y0, y1, y0<=y1 and 1 or -1 do grid:set(x1, y, 1) end
end

local function arch_corridor(arch, x0, y0, x1, y1)
    local grid = arch.grid
    for x=x0, x1, x0<=x1 and 1 or -1 do -- Horizontal.
        grid:set(x, y0, 1)
        arch_wall_if_not_floor(arch, x, y0-1)
        arch_wall_if_not_floor(arch, x, y0+1)
    end
    -- Four corners of elbow.
    arch_wall_if_not_floor(arch, x1-1, y0-1) arch_wall_if_not_floor(arch, x1+1, y0-1)
    arch_wall_if_not_floor(arch, x1-1, y0+1) arch_wall_if_not_floor(arch, x1+1, y0+1)
    for y=y0, y1, y0<=y1 and 1 or -1 do -- Vertical.
        grid:set(x1, y, 1)
        arch_wall_if_not_floor(arch, x1-1, y)
        arch_wall_if_not_floor(arch, x1+1, y)
    end
end

local function arch_room0(arch, hW, hH)
    local cx, cy = math.floor(arch.w/2), math.floor(arch.h/2)
    return arch_carve(arch, AABB(cx-hW, cy-hH, cx+hW, cy+hH))
end

local function arch_grow(arch, room, w, h, pad)
    local rng, leaf = arch.rng, AABB()
    if not pad then pad = 1 end
    for tries=1, 20 do
        local d = rng:next_range(4)
        local x0 = rng:next_range(room.x0-w, room.x1)
        local y0 = rng:next_range(room.y0-h, room.y1)
            if d == 1 then y0 = room.y0 - pad - h   -- Top
        elseif d == 2 then x0 = room.x1 + pad       -- Right
        elseif d == 3 then y0 = room.y1 + pad       -- Bottom
        else--[[d== 4 ]]   x0 = room.x0 - pad - w   -- Left
        end
        leaf.x0, leaf.y0, leaf.x1, leaf.y1 = x0, y0, x0+w, y0+h
        if arch_is_valid(arch, leaf) then
            --local lx, ly = AABB_midpoint(leaf)
            --local rx, ry = AABB_midpoint(room)
            local lx, ly = rng:next_range(leaf.x0+1, leaf.x1-1), rng:next_range(leaf.y0+1, leaf.y1-1)
            local rx, ry = rng:next_range(room.x0+1, room.x1-1), rng:next_range(room.y0+1, room.y1-1)
            arch_carve(arch, leaf)
            if rng:next_double() < 0.5 then arch_corridor(arch, lx, ly, rx, ry)
            else                            arch_corridor(arch, rx, ry, lx, ly)
            end
            return room
        end
    end
end

local ceil, max = math.ceil, math.max
local function arch_rand_room(arch)
    local rng, n = arch.rng, #arch
    assert(n > 0)
    local room = arch[rng:next_range(n)]
    local w = max(4, ceil(rng:next_normal(12, 2)))
    local h = max(4, ceil(rng:next_normal( 5, 2)))
    local p = rng:next_double() < 0.05 and 40 or 1
    return arch_grow(arch, room, w, h, p)
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
