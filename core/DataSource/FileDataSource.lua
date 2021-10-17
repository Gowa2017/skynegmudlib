---@class FileDataSource : Class
local FileDataSource = class()

function FileDataSource:_init(config, rootPath)
  config = config or {}
  self.config = config
  self.root = rootPath
end

---Parse [AREA] and [BUNDLE] template in the path
---@param config string | table  if string, is a path, else is a config table
---@return string
function FileDataSource:resolvePath(config)
  local cfgPath, bundle, area = config.path, config.bundle, config.area

  if not self.root then error("No root configured for DataSource"); end

  if not cfgPath then error("No path for DataSource"); end

  if cfgPath:find("%[AREA%]") and not area then
    error("No area configured for path with [AREA]");
  end

  if cfgPath:find("%[BUNDLE%]") and not bundle then
    error("No bundle configured for path with [BUNDLE]");
  end
  cfgPath, _ = cfgPath:gsub("%[AREA%]", area or "")
  cfgPath, _ = cfgPath:gsub("%[BUNDLE%]", bundle or "")

  return self.root .. "/" .. cfgPath
end

return FileDataSource
