local uv = vim.loop

local Server = {}
Server.__index = Server

function Server:new(opts)
    opts = opts or {}
    local port = opts.port or 8080
    local self = setmetatable({}, Server)
    self.port = port
    self.server = nil
    return self
end

function Server:start(bad)
    if self.server then
        print("Server already running")
        return
    end
    local filename = bad and "bad.json" or "good.json"
    local port = self.port

    self.server = uv.new_tcp()
    assert(self.server:bind("0.0.0.0", port))
    self.server:listen(128, function(err)
        assert(not err, err)
        local client = uv.new_tcp()
        self.server:accept(client)
        client:read_start(function(err, chunk)
            assert(not err, err)
            if not chunk then
                client:close()
                return
            end

            local path = chunk:match("GET%s+([^%s]+)%s+HTTP")
            path = path or "/"
            local responsepath = ("%s/tests/fixtures/endpoints/%s/%s")
                :format(uv.cwd(), path, filename)

            local ok, file = pcall(vim.fn.readfile, responsepath)
            local body, status
            if not ok then
                status = "404 Not Found"
                body = "Not Found"
            else
                status = "200 OK"
                body = table.concat(file, "\n")
            end

            local resp = "HTTP/1.1 " .. status .. "\r\n" ..
                         "Content-Type: application/json\r\n" ..
                         "Content-Length: " .. #body .. "\r\n" ..
                         "Connection: close\r\n\r\n" ..
                         body

            client:write(resp, function()
                client:shutdown()
                client:close()
            end)
        end)
    end)
    print("Server started")
end

function Server:stop()
    if self.server then
        self.server:close()
        self.server = nil
        print("Server stopped")
    else
        print("Server not running")
    end
end

return setmetatable({}, {
    __call = function(_, ...)
        return Server:new(...)
    end
})
