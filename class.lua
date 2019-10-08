--[[ class.lua -- Tiny, unintrusive class system.
To use a FFI-backed instance, define a __ctype field with the ctype.
]]

local ffi = require("ffi")

local function new_lua(mt, ...)
    local inst, init = setmetatable({}, mt), mt.init
    if init then init(inst, ...) end
    return inst
end

local function new_ffi(mt, ...)
    local inst, init = mt.__ctype(...), mt.init -- Triggers __new metamethod.
    if init then init(inst, ...) end
    return inst
end

local function class(path)
    local mt = package.loaded[path]
    if mt then return mt end
    local mt = require(path)
    if mt.__index == nil then mt.__index = mt end
    if mt.new == nil then
        if mt.__ctype        then mt.new = new_ffi
        elseif mt.new == nil then mt.new = new_lua
        end
    end
    if mt.__ctype then ffi.metatype(mt.__ctype, mt) end
    return mt
end

return class
