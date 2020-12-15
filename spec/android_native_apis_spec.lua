local tango = require 'tango'
local client_backend = "socket"
local config = { address = os.getenv("TANGO_SERVER") or "localhost" }
local connect = tango.client[client_backend].connect

local client, android, utils

if config.address == "localhost" then
  os.execute("adb forward tcp:12345 tcp:12345")
end

describe("#BasicTests : `android` module with native API access through FFI", function()
  setup(function()
      client = connect(config)
      android = client.require "android"
      utils = client.require "utils"
    end)

  it("can call some basic runtime functions",
    function()
      android.DEBUG(debug.getinfo(1).source)
      utils.sleep(1)
      -- TODO: add some more function calls with checkable result
    end)
  
end)
