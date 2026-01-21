
local pegasus = require('pegasus')

Server = {}

function Server:start(bad)
    local filename = bad and "bad.json" or "good.json"

    self.pegasus = pegasus:new({ port = '80' })

    self.pegasus:start(function(request, response)
        local path = request:path()
        local responsepath = ("%s/tests/fixtures/endpoints/%s/%s")
            :format(vim.uv.cwd(), path, filename)

        local ok, file = pcall(vim.fn.readfile, responsepath)
        if not ok then
            response:statusCode(404)
            response:write("Not Found")
            return
        end

        response:statusCode(200)
        response:write(table.concat(file, "\n"))
    end)
end

function Server:stop()
    if self.pegasus == nil then return end
    self.pegasus:stop()
end

return Server
