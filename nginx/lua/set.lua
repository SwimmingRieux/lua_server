local cjson = require "cjson.safe"
local redis_handler = require "redis_handler"
local rate_limiter = require "rate_limiter"

ngx.req.read_body()
local args = ngx.req.get_uri_args()

if not rate_limiter.check() then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 429
    ngx.say(cjson.encode({error = "Rate limit exceeded"}))
    return
end

local key = args.key
local value = args.value

if not key then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 400
    ngx.say(cjson.encode({error = "Missing 'key'"}))
    return
end

if not value then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 400
    ngx.say(cjson.encode({error = "Missing 'value'"}))
    return
end

local red, redis_err_or_shard = redis_handler.get_redis_connection(key)

if not red then
    ngx.header["Content-Type"] = "application/json"
    ngx.status = 500
    ngx.say(cjson.encode({error = redis_err_or_shard}))
    return
end

red:set(key, value)
red:close()

ngx.header["Content-Type"] = "application/json"
ngx.status = 200
ngx.say(cjson.encode({
    key = key,
    value = value,
    status = "OK",
    shard = redis_err_or_shard
}))