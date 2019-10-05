-- Random number generation.
local function rng_int(i) return math.floor(math.random()*i) end
local seed = os.time()
math.randomseed(seed)

-- Digger
function grid_init(self, w, h, v0)
    self.w, self.h = w, h
    for i=0, w*h-1 do
        self[i] = v0
    end
    return self
end
function grid_get(self, x, y)
    if x < 0 or x >= self.w or y < 0 or y >= self.h then return 0 end
    return self[x + y*self.w]
end
function grid_set(self, x, y, v)
    self[x + y*self.w] = v
end
function grid_neigh4(self, x, y)
    return grid_get(self, x, y-1), grid_get(self, x+1, y),
           grid_get(self, x, y+1), grid_get(self, x-1, y)
end
function grid_neigh8(self, x, y)
    return grid_get(self, x,   y-1), grid_get(self, x+1, y-1),
           grid_get(self, x+1, y  ), grid_get(self, x+1, y+1),
           grid_get(self, x,   y+1), grid_get(self, x-1, y+1),
           grid_get(self, x-1, y  ), grid_get(self, x-1, y-1)
end


--[[
    1     | The bit pattern indicates the direction:
    ^     | 0001 North
 8 <+> 2  | 0010 East
    v     | 0100 South
    4     | 1000 West
]]
local WALL_SPRITESHEET = { [0] = " ", "╵", "╶", "└", "╷", "│", "┌", "├", "╴", "┘", "─", "┴", "┐", "┤", "┬", "┼" }
local DIRT_SPRITE = "░"
--[[
1 2
 +
8 4
]]
local VOID_SPRITESHEET = { [0] = " ", "┘", "└", "─", "┌", "╲", "│", "┐", "┐", "│", "╱", "┌", "─", "└", "┘", "%"}

function grid_draw(self, out)
    out:write("Seed: ", seed, "\n")
    for y=0, self.h-1 do
        for x=0, self.w-1 do
            local n1, n2, n3, n4, n5, n6, n7, n8 = grid_neigh8(self, x, y)
            local ss = n1+n2+n3+n4+n5+n6+n7+n8
            if grid_get(self, x, y) ~= 0 or ss == 0 then
                out:write(" ")
            else
                --local c = DIRT_SPRITE
                --if ss == 4 or ss == 5 then ss, n2, n4, n6, n8 = 1, 1-n2, 1-n4, 1-n6, 1-n8 end
                --if ss == 1 then
                --    if n2 == 1 then c = "└"
                --    elseif n4 == 1 then c = "┌"
                --    elseif n6 == 1 then c = "┐"
                --    elseif n8 == 1 then c = "┘"
                --    end
                --elseif ss == 2 or ss == 3 then
                --    if n1 == 0 and n5 == 0 then c = "│"
                --    elseif n3 == 0 and n7 == 0 then c = "─"
                --    elseif n1 == 0 and n3 == 0 then c = "└"
                --    end
                --end
                --out:write(c)
                local wall_i = 0
                if n1 == 0 then wall_i = wall_i + 1 end
                if n3 == 0 then wall_i = wall_i + 2 end
                if n5 == 0 then wall_i = wall_i + 4 end
                if n7 == 0 then wall_i = wall_i + 8 end
                out:write(WALL_SPRITESHEET[wall_i] or DIRT_SPRITE)
            end
        end
        out:write("\n")
    end
    out:write("\n") -- "\27[47m \27[0m"
end

local d = grid_init({}, 135, 35-1, 0)
local x, y, dirs = 67, 17, {}
for i=1, 1000 do
    dirs[1], dirs[2], dirs[3], dirs[4] = nil, nil, nil, nil
    dirs[#dirs+1] = grid_get(d, x+1, y  ) ~= 1 and 1 or nil
    dirs[#dirs+1] = grid_get(d, x,   y+1) ~= 1 and 2 or nil
    dirs[#dirs+1] = grid_get(d, x-1, y  ) ~= 1 and 3 or nil
    dirs[#dirs+1] = grid_get(d, x,   y-1) ~= 1 and 4 or nil
    --print(#dirs, dirs[1], dirs[2], dirs[3], dirs[4])
    local n = #dirs
    if n == 0 then break end
    local j = dirs[1+rng_int(n)]
        if j == 1 then x = x + 1
    elseif j == 2 then y = y + 1
    elseif j == 3 then x = x - 1
    elseif j == 4 then y = y - 1
    end
    grid_set(d, x, y, 1)
end

for y=0, d.h-1 do
    for x=0, d.w-1 do
        if grid_get(d, x, y) == 0 then
            local n1, n2, n3, n4, n5, n6, n7, n8 = grid_neigh8(d, x, y)
            local ss = n1+n2+n3+n4+n5+n6+n7+n8
            if ss >= 5 then
                grid_set(d, x, y, 1)
            end
        end
    end
end


grid_draw(d, io.stdout)
