local tango = require 'tango'
local client_backend = "socket"
local config = { address = os.getenv("TANGO_SERVER") or "localhost" }
local connect = tango.client[client_backend].connect

local client, android

if config.address == "localhost" then
  os.execute("adb forward tcp:12345 tcp:12345")
end

describe("#BasicTests : `android` module with JVM access", function()
  setup(function()
      client = connect(config)
      android = client.require "android"
    end)

  it("can call some basic runtime functions",
    function()
      local ext_storage_path = android.getExternalStoragePath()
      assert.is_equal( "string", type(ext_storage_path) )
      assert.truthy( ext_storage_path:find('/') )
      local ext_files_dir = android.externalFilesDir
      assert.is_equal( "string", type(ext_files_dir) )
      assert.truthy( ext_files_dir:find(ext_storage_path), "android.externalFilesDir does not contain android.getExternalStoragePath()" )
    end)

  it("can get some device info",
    function()
      local product,version,name,flavor = android.getProduct(),android.getVersion(),
                                          android.getName(),android.getFlavor()
      assert.is_equal( "string", type(product) )
      assert.is_equal( "string", type(version) )
      assert.is_equal( "string", type(name) )
      assert.is_equal( "string", type(flavor) )
      assert.truthy( string.find( product..'/'..version..'/'..name..'/'..flavor,
          "%/luajit%-launcher%-debug%/") )
    end)

  it("can get some device values",
    function()
      local scr_wid = android.getScreenWidth()
      assert.is_equal( "number", type(scr_wid) )
      assert.truthy( scr_wid>0 and scr_wid<9999 )
      local scr_bri = android.getScreenBrightness()
      assert.is_equal( "number", type(scr_bri) )
      assert.truthy( scr_bri>0 and scr_bri<9999 )
      local batt = android.getBatteryLevel()
      assert.is_equal( "number", type(batt) )
      assert.truthy( batt>0 and batt<9999 )
    end)

  it("can handle Android clipboard",
    function()
      local clipb = android.getClipboardText()
      assert.is_equal( "string", type(clipb) )
      android.setClipboardText("Hello, Android world!")
      clipb = android.getClipboardText()
      assert.is_equal( "Hello, Android world!", clipb )
    end)
  
  it("can exec a command in a subprocess",
    function()
      local out = android.stdout("uname", "-a")
      assert.truthy( out:find("Linux") )
    end)
  
  it("can handle exceptions in jvm",
    function()
      local fn_FindClass_str = [[
        name = ...
        return android.jni:jpcallInContext(function(jni)
          return jni.env[0].FindClass(jni.env, name)
        end)
      ]]
      local remFindClass = client.loadstring( fn_FindClass_str )
      assert.is_not.equal(nil, remFindClass, "failed to push fn remFindClass() to server")
      assert.equal('function', remFindClass.__tango_type)
      local ok, aClazz = remFindClass("java/lang/String")
      assert.equal(true, ok)
      assert.equal("cdata<void *>", aClazz.__tango_type)
      ok, aClazz = remFindClass("java/lang/NONEXISTANT")
      assert.equal(false, ok)
      assert.equal("string", type(aClazz))
      assert.truthy(aClazz:find("Didn't find class"))
    end)

end)
