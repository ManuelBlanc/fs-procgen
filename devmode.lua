-- Debugging utilities.
--
-- Usage of __trace__:
--  __trace__("fmt", ...)           Print a message.
--  __trace__(2, "fmt", ...)        Print a message at a given level.
--  __trace__[func] = true          Toggle tracing for a specific function.
--  __trace__["path.lua"] = true    Toggle tracing for all functions in a file/module.
--  __trace__["*"] = true           Toggle tracing for ALL functions.

local format, sub, getinfo, stderr = string.format, string.sub, debug.getinfo, io.stderr

--- Retrieve a tag + info table of the function at a given stack level.
local function getcaller(lvl)
    local info = getinfo(1 + lvl, "lSf")
    return format(
        "\027[36m%15s\27[0m:\027[31m%3d\27[0m",
        sub(info.short_src, -15, -1), info.currentline
    ), info
end

-- Trace definition.
rawset(_G, "__trace__", setmetatable({}, {
    __call = function(self, lvl, ...)
        if type(lvl) == "string" then return __trace__(1, lvl, ...) end
        local locstr, info = getcaller(1 + lvl)
        if self[assert(info.func)] == nil then
            if self[assert(info.short_src)] == nil then
                if not self["*"] then return end
            elseif not self[info.short_src] then return end
        elseif not self[info.func] then return end
        return stderr:write(format("%s: %s\n", locstr, format(...)))
    end,
}))

-- Forbid reads+writes to the global environment table.
setmetatable(_G, {
    __index    = function(_, k) error("Accessed undeclared global: "..tostring(k), 2) end,
    __newindex = function(_, k) error("Polluted global environment: "..tostring(k), 2) end,
})
