-- Platform specific FFI bindings. Reads the OS from jit.os.

assert(jit, "LuaJIT is required")

local ffi = require("ffi")
local isatty, sleep

if jit.os == "Windows" then

    -- https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-sleep?redirectedfrom=MSDN
    ffi.cdef[[ void Sleep(unsigned int dwMilliseconds); ]]

    isatty = function() return false end
    sleep = function(msec) return ffi.C.Sleep(msec) end

else-- Assume we're on a POSIX system.

    -- https://pubs.opengroup.org/onlinepubs/009695399/functions/usleep.html
    -- https://pubs.opengroup.org/onlinepubs/009695399/functions/isatty.html
    ffi.cdef[[
        int usleep(unsigned usec);
        int fileno(void *fp);
        int isatty(int fd);
    ]]

    isatty = function(file) return 1 == ffi.C.isatty(ffi.C.fileno(file)) end
    sleep = function(msec) return ffi.C.usleep(1000*msec) end

end

return {
    isatty = isatty,
    sleep = sleep,
}