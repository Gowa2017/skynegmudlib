local function bind(fn, obj) return function(...) return fn(obj, ...) end end
local function trim(s) return s:gsub("^%s*(.-)%s*$", "%1") end
local function loadScript(path)
  local f, err = loadfile(path, "bt")
  assert(f, err)
  return f()
end

local bundleScript = {}
local function loadBundleScript(script, bundle)
  local src  = debug.getinfo(2, "S").short_src
  bundle = bundle or src:match("./bundles/([%a%w-_]+)/.*")
  assert(bundle,
         "loadBundleScript must used in bundle script or you can pass the bundle name as the sencod parameter")
  local path = string.format("./bundles/%s/%s.lua", bundle, script)
  if not bundleScript[path] then bundleScript[path] = loadScript(path) end
  return bundleScript[path]
end

---generate a table which represent a type of error
---@param string string errormessage
local function errortype(string)
  return setmetatable({}, { __tostring = function() return string end })
end

return {
  bind             = bind,
  trim             = trim,
  loadScript       = loadScript,
  loadBundleScript = loadBundleScript,
  errortype        = errortype,
}
