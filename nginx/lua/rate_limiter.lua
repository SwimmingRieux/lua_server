local _M = {}
local cjson = require "cjson.safe"

local WINDOW_SIZE = 60
local REQUEST_LIMIT = 60
local BLOCK_DURATION = 15

local now = ngx.now
local shared_dict = ngx.shared.rate_limit_store

function _M.check()
    local client_ip = ngx.var.remote_addr
    local record = shared_dict:get(client_ip)
    local current_time = now()

    if record then
        local data = cjson.decode(record)
        local window_start_time = data.ts
        local request_count = data.count
        local blocked_until_time = data.blocked_until or 0

        if blocked_until_time > current_time then
            return false, "Rate limit exceeded"
        end

        if (blocked_until_time > 0 and blocked_until_time <= current_time) or (current_time - window_start_time >= WINDOW_SIZE) then

            data.ts = current_time
            data.count = 1
            data.blocked_until = 0
            shared_dict:set(client_ip, cjson.encode(data))
            return true
        else

            if request_count < REQUEST_LIMIT then
                data.count = request_count + 1
                shared_dict:set(client_ip, cjson.encode(data))
                return true
            else

                data.blocked_until = current_time + BLOCK_DURATION
                shared_dict:set(client_ip, cjson.encode(data))
                return false, "Rate limit exceeded"
            end
        end
    else

        local first = {
            ts = current_time,
            count = 1,
            blocked_until = 0
        }
        shared_dict:set(client_ip, cjson.encode(first))
        return true
    end
end

return _M