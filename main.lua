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

require "devmode"

local class = require("class")

local Grid = class("grid")
local RNG = class("rng")
local Architect = class("architect")
local render = require("render")

local function rgb(r, g, b) return 16 + 36*r + 6*g + b end
local function palette(v, x, y, SGR, rng)
    local r = rng:next_range(0, 15) -- Stepping the RNG has side-effects, we always do it.
        if v == 0 then return SGR("48;5;0",             SGR("38;5;15",              " "))
    elseif v == 1 then return SGR("48;5;"..(240 + r%2), SGR("38;5;"..(240 + r%2),   "."))
    elseif v == 2 then return SGR("48;5;"..234,         SGR("38;5;234",             "#"))
    end
end

-- Initialize the seed with the Unix time + entropy from a random address.
local seed = os.time() + tonumber(tostring{}:match("%x+"), 16)
local width, height = 80, 24

local function uassert(ok, ...)
    if ok then return ok, ... end
    io.stderr:write("procgen: ", ...)
    io.stderr:write("\n")
    os.exit(1)
end

local function num_or_err(val, description)
    return uassert(tonumber(val), "number expected for "..description)
end

local function usage()
    io.stderr:write[[
Procedural level generation: procgen [options] [output]
  -?        Show this help message.
  -c        Enable colorized output using ANSI escape sequences.
  -p        Disable colorized output.
  -s seed   Set the level generation seed.
  -w width  Set the level width.
  -h height Set the level height.
  --        Stop handling options.
  -         Use stdout as output.
]]
    os.exit(1)
end

local function parse_args()
    local n = 1
    while n <= #arg do
        local a = arg[n]
        if a:sub(1, 1) == "-" and a ~= "-" then
            table.remove(arg, n)
            if a == "--" then return end
                if a == "-c" then render.set_color(true)
            elseif a == "-p" then render.set_color(false)
            elseif a == "-?" then usage()
            else
                if a == "-s" then seed = num_or_err(table.remove(arg, n), "-s")
                elseif a == "-w" then width  = num_or_err(table.remove(arg, n), "-w")
                elseif a == "-h" then height = num_or_err(table.remove(arg, n), "-h")
                else io.stderr:write("Unknown argument: ", a, "\n") usage()
                end
            end
        else
            n = n + 1
        end
    end
end

local ffi = require("ffi")
ffi.cdef[[ int usleep(unsigned usec); ]] -- Only tested on OSX.

local function main()
    local g = Grid:new(width, height, 0)
    local a1 = Architect:new(g, RNG:new(seed))
    local r = a1:room0(3, 3)

    local function display()
        render.draw(g, palette, RNG:new())
        --io.flush()
        --ffi.C.usleep(100000)
    end

    local energy = 60
    repeat
        if a1:rand_room() then energy = energy - 5
        else                   energy = energy - 1
        end
    until energy <= 0
    display()
end

if arg then parse_args() end
main()
