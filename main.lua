-- Main entrypoint to the level generation.
-- For use as a standalone console command.

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

--- Initialize the seed with the Unix time + entropy from a random address.
local seed = os.time() + tonumber(tostring{}:match("0x%x+"), 16)
local width, height = 80, 24
local out, color = io.stdout, nil

--- Quit the program with an error message.
local function die(...)
    io.stderr:write("procgen: ", ...)
    io.stderr:write("\n")
    os.exit(1)
end

local function num_or_err(val, opt)
    local num = tonumber(val)
    if num then return num end
    die("Numeric argument expected for `-", opt, "'")
end

--- Print usage information on stderr.
local function usage()
    io.stderr:write[[
Procedural level generation: procgen [options]
  -?        Show this help message.
  -c        Enable colorized output using ANSI escape sequences.
  -p        Disable colorized output.
  -s seed   Set the level generation seed.
  -w width  Set the level width.
  -h height Set the level height.
  --        Stop handling options.
]]
end

-- Parse the command line arguments (in the predefined global `arg').
local function parse_args()
    local n, remove = 1, table.remove
    while n <= #arg do
        local a = arg[n]
        if a:sub(1, 1) == "-" and a ~= "-" then
            remove(arg, n)
            if a == "--" then return end
            for i=2, #a do
                local c = a:sub(i, i)
                -- Handle flags.
                    if c == "c" then color = true
                elseif c == "p" then color = false
                elseif c == "?" then usage() os.exit(0)
                else
                    -- Handle options.
                        if c == "s" then seed   = num_or_err(remove(arg, n), "s")
                    elseif c == "w" then width  = num_or_err(remove(arg, n), "w")
                    elseif c == "h" then height = num_or_err(remove(arg, n), "h")
                    else die("Unknown option: `-", c, "'")
                    end
                end
            end
        else
            n = n + 1
        end
    end
end


--- Main function.
local function main()
    local g = Grid:new(width, height, 0)
    local a1 = Architect:new(g, RNG:new(seed))
    local r = a1:room0(3, 3)

    -- local function rgb(r, g, b) return 16 + 36*r + 6*g + b end
    -- The palette method is used to convert grid items to displayable glyphs.
    local function palette(v, x, y, SGR, rng)
        local r = rng:next_range(0, 15) -- Stepping the RNG has side-effects, we always do it.
            if v == 0 then return SGR("48;5;0",             SGR("38;5;15",              " "))
        elseif v == 1 then return SGR("48;5;"..(240 + r%2), SGR("38;5;"..(240 + r%2),   "."))
        elseif v == 2 then return SGR("48;5;"..234,         SGR("38;5;234",             "#"))
        end
    end

    local function display()
        render.draw(g, palette, RNG:new(), out, color)
        --io.flush()
        --ffi.C.usleep(100000)
    end

    -- Energy is an abstract measure of how many features there will be in the dungeon.
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
