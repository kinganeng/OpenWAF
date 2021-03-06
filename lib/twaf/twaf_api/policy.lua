
-- Copyright (C) Miracle
-- Copyright (C) OpenWAF

local _M = {
    _VERSION = "0.0.1"
}

local twaf_func = require "lib.twaf.inc.twaf_func"
local arr_index = "arr_tonumber"

_M.api = {}
_M.help = {}
_M.api.policy = {}

-- get policy config e.g: GET host/path/policy/policy_uuid
_M.api.policy.get    = function(_twaf, log, u)
    
    u[1] = "config"
    table.insert(u, 2, "twaf_policy")
    
    -- _M.api.config.get(_twaf, log, u) --[[
    
    local i =  2
    local v = _twaf.config
    repeat
    
    local str = u[i]
    if not str then
        break
    end
    
    if type(v) ~= "table" then
        log.success = 0
        log.reason  = "the value of "..u[i-1].." is not a table"
        return
    end
    
    local from, to, err = str:find(arr_index)
    if from and to then
    
        local t = next(v)
        if t and t~= 1 then
            log.success = 0
            log.reason  = "the value of "..u[i-1].."is not a array"
            return
        end
        
        local max_len = #v -- post + 1
        
        str = tonumber(str:sub(to+1))
        
        if type(str) ~= "number" then
            log.success = 0
            log.reason = "the value of "..arr_index.." must be a number"
            return
        end
        
        if str == 0 then
            log.success = 0
            log.reason = "the value of "..arr_index.." can't be '0'"
            return
        end
        
        if str > max_len then
            log.success = 0
            log.reason = "the value of "..arr_index.." can't be greater than "..max_len
            return
        end
    end
    
    v = v[str]
    if v == nil then v = "nil" end
    
    i = i + 1
    
    until false
    
    log.result = v
    
    -- ]]
    
    if not u[4] and log.result == "nil" then
        log.result  = nil
        log.success = 0
        log.reason  = "No policy '"..u[3].."'"
        return
    end
    
end

-- post policy config e.g: POST host/path/policy/policy_uuid
_M.api.policy.post   = function(_twaf, log, u)

-- check request body
    local data = twaf_func.api_check_json_body(log)
    if not data then
        return
    end
    
    if type(data.config) ~= "table" then
        log.success = 0
        log.reason  = "rules: table expected, got "..type(data.config)
        return
    end
    
    if not u[2] then
        log.success = 0
        log.reason  = "Not specified policy uuid"
        return
    end
    
    local conf = _twaf.config.twaf_policy
    
    if conf[u[2]] then
        log.success = 0
        log.reason  = "Policy '"..u[2].."' have exist"
        return
    end
    
    local tb = twaf_func:copy_table(_twaf.config.twaf_default_conf)
    
    for modules, v in pairs(data.config) do
        if type(v) == "table" and #v == 0 then
            for key, value in pairs(v) do
                if tb[modules] == nil then
                    tb[modules] = {}
                end
                
                tb[modules][key] = value
            end
        else
            tb[modules] = v
        end
    end
    
    log.result = tb
    conf[u[2]] = tb
    conf.policy_uuids = conf.policy_uuids or {}
    conf.policy_uuids[u[2]] = 1
    
    return
end

-- put policy config e.g: PUT host/path/policy/policy_uuid
_M.api.policy.put    = function(_twaf, log, u)

-- check request body
    local data = twaf_func.api_check_json_body(log)
    if not data then
        return
    end
    
    if type(data.config) ~= "table" then
        log.success = 0
        log.reason  = "rules: table expected, got "..type(data.config)
        return
    end
    
    local conf = _twaf.config.twaf_policy
    
    if not u[2] then
        log.success = 0
        log.reason  = "Not specified policy uuid"
        return
    end
    
    if not conf[u[2]] then
        log.success = 0
        log.reason  = "No policy '"..u[2].."'"
        return
    end
    
    local tb = twaf_func:copy_table(_twaf.config.twaf_default_conf)
    
    for modules, v in pairs(data.config) do
        if type(v) == "table" and #v == 0 then
            for key, value in pairs(v) do
                if tb[modules] == nil then
                    tb[modules] = {}
                end
                
                tb[modules][key] = value
            end
        else
            tb[modules] = v
        end
    end
    
    log.result = tb
    conf[u[2]] = tb
    
    return
end

-- delete policy config e.g: DELETE host/path/policy/policy_uuid
_M.api.policy.delete = function(_twaf, log, u)

    local conf = _twaf.config.twaf_policy
    
    if not u[2] then
        log.success = 0
        log.reason  = "Not specified policy uuid"
        return
    end
    
    log.result = conf[u[2]] or "No policy '"..u[2].."'"
    conf.policy_uuids[u[2]] = nil
    conf[u[2]] = nil
    
    return
end

_M.help.policy = {
    "GET host/path/policy/policy_uuid",
    "POST host/path/policy/policy_uuid",
    "PUT host/path/policy/policy_uuid",
    "DELETE host/path/policy/policy_uuid"
}
    
return _M