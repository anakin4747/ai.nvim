local uv = vim.loop

local Server = {}
Server.__index = Server

-- taken from :h luv-file-system-operations
local function readfile(path, callback)
    vim.uv.fs_open(path, "r", 438, function(err, fd)
        assert(not err, err)
        vim.uv.fs_fstat(fd, function(err, stat)
            assert(not err, err)
            vim.uv.fs_read(fd, stat.size, 0, function(err, data)
                assert(not err, err)
                vim.uv.fs_close(fd, function(err)
                    assert(not err, err)
                    return callback(data)
                end)
            end)
        end)
    end)
end

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

            local path = chunk:match("%w+%s+/([^%s]+)%s+HTTP")
            if path == nil then
                print("no path found")
                client:close()
                return
            end

            local responsepath = ("%s/tests/fixtures/endpoints/%s/%s")
                :format(uv.cwd(), path, filename)
            print("Serving file:", responsepath)

            local ok, file = pcall(readfile, responsepath)
            local body, status
            print("File read result:", ok, file)
            if not ok then
                status = "404 Not Found"
                body = "Not Found\n"
            else
                status = "200 OK"
                body = table.concat(file, "\n")
            end

            local resp = "HTTP/1.1 " .. status .. "\r\n" ..
                         "Content-Type: application/json\r\n" ..
                         "Content-Length: " .. #body .. "\r\n" ..
                         "Connection: close\r\n\r\n" ..
                         body

            print("Sending response:", resp)

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
