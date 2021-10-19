local function bind(fn, obj) return function(...) return fn(obj, ...) end end
local function trim(s) return s:gsub("^%s*(.-)%s*$", "%1") end
local function loadScript(path)
  local f, err = loadfile(path, "bt")
  assert(f, err)
  return f()
end
local function loadBundleScript(script, bundle)
  local src = debug.getinfo(2, "S").short_src
  bundle = bundle or src:match("./bundles/([%a%w-_]+)/.*")
  assert(bundle,
         "loadBundleScript must used in bundle script or you can pass the bundle name as the sencod parameter")
  return loadScript(string.format("./bundles/%s/%s.lua", bundle, script))
end

return {
  bind             = bind,
  trim             = trim,
  loadScript       = loadScript,
  loadBundleScript = loadBundleScript,
}
