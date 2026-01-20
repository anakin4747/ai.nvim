
local pegasus = require('pegasus')

local server = pegasus:new({
    port = '80',
    location = 'root/'
})

-- Helper to read file content
local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

-- Resolve absolute path relative to project root
local function get_endpoint_path(subpath)
    local cwd = vim.loop.cwd()
    return cwd .. "/endpoints/" .. subpath
end

server:start(function(request, response)
    local path = request:path()
    print("Request path: " .. path)

    if path == '/copilot_internal/v2/token' then
        response:statusCode(200)
        response:write(read_file(get_endpoint_path('token/good.json')))
    elseif path == '/models' then
        response:statusCode(200)
        response:write(read_file(get_endpoint_path('models/good.json')))
    elseif path == '/chat/completions' then
        response:statusCode(200)
        response:write(read_file(get_endpoint_path('chats/good.json')))
    else
        response:statusCode(404)
        response:write("Not Found")
    end
end)

