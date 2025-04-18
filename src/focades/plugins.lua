local Log       = require("src.log")
local cjson     = require("cjson")

local Plugins   <const> = { Plugins = nil, Args = nil }
Plugins.__index = Plugins

function Plugins:new()
    return setmetatable({}, Plugins)
end

function Plugins:setup(plugins, args)
    self.Plugins = plugins
    self.Args = args
end

function Plugins:_process_response(headers, body, endpoint)
    local function recursive_json_to_string(json, depth)
        local result, indent <const> = "", string.rep("  ", depth)

        for key, value in pairs(json) do
            if type(value) == "table" then
                result = result .. indent .. key .. ":\n" .. recursive_json_to_string(value, depth + 1) .. "\n"
            else
                result = result .. indent .. key .. " : " .. tostring(value) .. "\n"
            end
        end

        return result
    end

    local code <const> = headers and headers:get(":status")
    if code == "200" then
        if not self.Args.fields["raw_data"] then
            local success, json <const> = pcall(cjson.decode, body)
            if success and json then
                return "[ " .. (endpoint or "Plugins List") .. " ]\n" .. recursive_json_to_string(json, 1)
            end
        end
        return body
    end
    return nil, "Failed to retrieve plugins: Unexpected response status : " .. tostring(code)
end

function Plugins:plugin()
    local method  <const> = self.Args.fields["method"]
    local endpoint <const> = self.Args.fields["endpoint"]
    local headers, body = self.Plugins:plugin(endpoint, {
        method = method,
        content_type = "text/plain",
        content = (function()
            if self.Args.fields["data"] then
                local d <const> = self.Args.fields["data"]

                if not d then
                    Log:error("Missing required argument: 'data'.")
                end

                if self.Args.fields["file"] then
                    local f, err <const> = io.open(d, "r")
                    if not f then
                        Log:error(string.format("Failed to open file '%s': %s", d, err or "Unknown error"))
                    end

                    local content = f:read("*all")
                    f:close()
                    return content
                end

                return d
            end
        end)()
    })

    local response, err <const> = self:_process_response(headers, body, endpoint)
    if response then
        Log:output(response)
    else
        Log:error(err)
    end
end

function Plugins:plugins()
    local headers, body <const> = self.Plugins:plugins()
    local response, err <const> = self:_process_response(headers, body, nil)

    if response then
        Log:output(response)
    else
        Log:error(err)
    end
end

return Plugins
