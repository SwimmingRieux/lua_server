local _M = {}
local bit = require("bit") -- Add this line to require the bit module

local function fnv1a_hash(str)
    local hash = 0x811C9DC5
    local prime = 0x01000193

    for i = 1, #str do
        hash = bit.bxor(hash, string.byte(str, i)) -- Change this line
        hash = (hash * prime) % 2^32
    end

    return hash
end

_M.hash = fnv1a_hash

return _M