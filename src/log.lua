local Log <const>  = {
    name = "infinity"
}

Log.__index        = Log


function Log:new()
    return setmetatable({}, Log)
end

function Log:info(content)
    print(string.format("%s ] %s", self.name, content))
end

function Log:error(content)
    print(string.format("%s ] %s", self.name, content))
    os.exit(1)
end

function Log:output(content)
    print(content)
end

return Log
