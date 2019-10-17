-- Pseudo-random number generator. Requires LuaJIT.
-- This implements the 32-bit version of Mersenne Twister (mt19937).
-- Reference: http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html

local floor, tonumber = math.floor, tonumber
local bit = require("bit")
local tobit, bxor, rshift, lshift, band = bit.tobit, bit.bxor, bit.rshift, bit.lshift, bit.band

--- Initialize the generator from a seed.
local function rng_seed(mt, seed)
    mt.i = 624
    mt[0] = seed or 5489
    for i=1, 623 do
        -- To multiply modulo 2^32, we coerce to a 64-bit unsigned integer and truncate to 32-bit.
        mt[i] = tobit(tonumber(0x6c078965ull * bxor(mt[i-1], rshift(mt[i-1], 30)) % 0x100000000) + i)
    end
    return mt
end

--- Extract a tempered value based on mt[i], twisting every 624 numbers.
local function rng_next(mt)
    -- assert(mt.i, "Generator was never seeded") -- Let it crash on the next line instead.
    if mt.i == 624 then
        for i=0, 623 do
            local x = band(mt[i], 0x80000000) + band(mt[(i+1) % 624], 0x7fffffff)
            mt[i] = bxor(mt[(i + 397) % 624], rshift(x, 1), x % 2 * 0x9908b0df)
        end
        mt.i = 0
    end
    local y = mt[mt.i]
    y = bxor(y,      rshift(y, 11)) -- Omitted bitwise AND with 0xffffffff.
    y = bxor(y, band(lshift(y,  7), 0x9d2c5680))
    y = bxor(y, band(lshift(y, 15), 0xefc60000))
    y = bxor(y,      rshift(y, 18))
    mt.i = mt.i + 1
    return y
end

--- Generate a random 32 bit unsigned integer.
local function rng_next_u32(mt)
    local x = rng_next(mt)
    return rshift(x, 1)*2 + band(x, 1) -- Clear the sign.
end

--- Generate a random 64 bit float.
local function rng_next_double(mt)
    return rng_next_u32(mt) * (2^-32)
end

--- Generate a random integer in the range [1, a] or [a, b].
local function rng_next_range(mt, a, b)
    local d = rng_next_double(mt)
    if not b then return 1 + floor(d * a)
    else          return a + floor(d * (b-a+1))
    end
end

--- Generate a normally distributed double with mean m and stddev s (default: N{1,0}).
local cos, sin, log, pi2 = math.cos, math.sin, math.log, 2*math.pi
local function rng_next_normal(mt, m, s) -- Box-muller transform.
    if not m then m = 0 end
    if not s then s = 1 end
    local u1, u2 = rng_next_double(mt), rng_next_double(mt)
    local z0 = (-2 * log(u1))^0.5 * cos(pi2 * u2)
    --local z1 = (-2 * log(u1))^0.5 * sin(1pi2 * u2)
    return z0*s + m
end

return {
    init = rng_seed, -- For use as a class.
    seed = rng_seed,
    next = rng_next,
    next_i32  = rng_next, -- Alias for consistency.
    next_u32 = rng_next_u32,
    next_double = rng_next_double,
    next_range = rng_next_range,
    next_normal = rng_next_normal,
}
