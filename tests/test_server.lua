
local pegasus = require('pegasus')

local server = pegasus:new({
  port='80',
  location='root/'
})

server:start(function (request, response)
  -- print "It's running..."
end)
