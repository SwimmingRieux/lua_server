local cjson = require "cjson"
local redis_handler = require "redis_handler"
local rate_limiter = require "rate_limiter"

ngx.req.read_body()
local args = ngx.req.get_uri_args()

if not rate_limiter.check_limit() then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 429
    ngx.say(cjson.encode({error = "Rate limit exceeded"}))
    return
end

local key = args.key

if not key then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 400
    ngx.say(cjson.encode({error = "Missing 'key'"}))
    return
end

local red, redis_err_or_shard = redis_handler.get_redis_connection(key)

if not red then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 500
    ngx.say(cjson.encode({error = redis_err_or_shard}))
    return
end

local value, err = red:get(key)
red:close()

local found = true
if value == ngx.null or value == nil then
    value = nil
    found = false
end

ngx.header["Content-Type"] = "application/json"
ngx.status = 200
ngx.say(cjson.encode({
    key = key,
    found = found,
    value = value,
    shard = redis_err_or_shard
}))