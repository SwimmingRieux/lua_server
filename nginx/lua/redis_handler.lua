local redis = require "resty.redis"
local fnv1a = require "fnv1a"

local _M = {}

local SHARDS = {
    shard1 = {primary = "redis1", replica = "redis1r"},
    shard2 = {primary = "redis2", replica = "redis2r"},
    shard3 = {primary = "redis3", replica = "redis3r"},
}

local function get_shard_name(key)
    local hash = fnv1a.hash(key)
    local shard_index = (hash % 3) + 1
    return "shard" .. shard_index
end

local function connect_to_redis(host)
    local red = redis:new()
    red:set_timeout(1000)

    local ok, err = red:connect(host, 6379)
    if not ok then
        return nil, err
    end
    return red
end

function _M.get_redis_connection(key)
    local shard_name = get_shard_name(key)
    local shard_info = SHARDS[shard_name]

    local red, err = connect_to_redis(shard_info.primary)
    if red then
        return red, shard_name
    end

    red, err = connect_to_redis(shard_info.replica)
    if red then
        return red, shard_name
    end

    return nil, "Redis unavailable", shard_name
end

return _M