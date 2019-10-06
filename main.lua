--[[ OBJECTIVES:
+ Generate interesting maps with variety in room sizes and layout.
+ Make sure the entire level is connected, and traversable.
  Make sure the completeness of the generated map is validated, either in
  design or as part of the code.
+ Ensure the APIs for interacting with the dungeon generator are designed in
  such a way that this project could be added to a real game. Imagine if we
  have a Roguelike game, and we wanted to to use your dungeon generator -
  take that into consideration when designing your APIs.
+ Focus on the data representation of the maps. Again, imagine that this
  would be a real game.
]]

require "dbg"

-- Tiny class system on top of require.
local function new(cl, ...)
    local inst, init = setmetatable({}, cl), cl.init
    return init and init(inst, ...) or inst
end
local function class(path)
    local cl = package.loaded[path]
    if cl then return cl end
    local cl = require(path)
    if cl.__index == nil then cl.__index = cl end
    if cl.new == nil then cl.new = new end
    return cl
end

local Grid = class("grid")
local RNG = class("rng")
local Architect = class("architect")
local render = require("render")

local _noise_rng = RNG:new()
local function noise2d(a, b)
    _noise_rng:seed(a*b)
    return _noise_rng:next_double()
end

--local function rgb(r, g, b) return 16 + 36*r + 6*g + b end
local function palette(v, x, y, SGR)
    local r = math.floor(noise2d(x, y)*9)
        if v == 0 then return SGR("48;5;0", " ")
    elseif v == 1 then return SGR("48;5;"..(247 + r), ".") -- 248
    elseif v == 2 then return SGR("48;5;"..(235 + r), "#") -- 243
    end
end

local ffi = require("ffi")
ffi.cdef[[ int usleep(unsigned usec); ]]

local g = Grid:new(120, 30, 0) -- 80x24
local a1 = Architect:new(g, RNG:new(os.time()))
local r = a1:room0(3, 3)
local attempts = 1
while attempts > 0 do
    if a1:rand_room() then
        attempts = attempts + 5
        io.stdout:write("\27[2J\27[1;1H")
        render.draw(g, palette)
        io.flush()
        ffi.C.usleep(500000)
    end
    attempts = attempts - 1
end

-- (>>=) :: m a -> (a -> m b) -> m b
