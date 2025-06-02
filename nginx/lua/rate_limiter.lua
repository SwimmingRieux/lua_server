local _M = {}

local limit_store = ngx.shared.rate_limit_store

function _M.check_limit()
    local client_ip = ngx.var.remote_addr
    local current_time = ngx.now()
    local limit_period = 60
    local max_requests = 60
    local block_duration = 15

    local key = "rate_limit:" .. client_ip

    
    local last_req_time = 0
    local req_count = 0
    local blocked_until = 0

    local data = limit_store:get(key)

    if data then
        local parsed_last_req_time, parsed_req_count, parsed_blocked_until = string.match(data, "(%d+):(%d+):(%d+)")

        last_req_time = tonumber(parsed_last_req_time) or 0
        req_count = tonumber(parsed_req_count) or 0
        blocked_until = tonumber(parsed_blocked_until) or 0
    end

    if blocked_until > current_time then
        return false
    end

    if (current_time - last_req_time) < limit_period then
        req_count = req_count + 1
        if req_count > max_requests then
            limit_store:set(key, string.format("%d:%d:%d", current_time, req_count, current_time + block_duration), block_duration)
            return false
        end
    else
        req_count = 1
        last_req_time = current_time
    end

    limit_store:set(key, string.format("%d:%d:%d", last_req_time, req_count, 0), limit_period + block_duration)
    return true
end

return _M