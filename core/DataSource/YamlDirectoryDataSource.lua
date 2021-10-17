local class          = require("pl.class")
local fs             = require("pl.file");
local dir            = require("pl.dir")
local path           = require("pl.path");
local sfmt           = string.format

local FileDataSource = require("core.DataSource.FileDataSource");
local YamlDataSource = require("core.DataSource.YamlDataSource");

---@class YamDirectoryDataSource : FileDataSource
local M              = class(FileDataSource)

function M:hasData(config)
  config = config or {}
  local filepath = self:resolvePath(config)
  return path.exists(filepath)
end

function M:fetchAll(config)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not self:hasData(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for YamlDirectoryDataSource",
               dirPath))
  end
  local data    = {}
  local files   = dir.getfiles(dirPath)
  for _, f in pairs(files) do
    if path.extension(f) ~= ".yml" then goto continue end
    local id = path.basename(f)
    data[id] = self:fetch(config, id)
    ::continue::
  end
  return data
end

function M:fetch(config, id)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for YamlDirectoryDataSource",
               dirPath))
  end

  local source  = YamlDataSource({}, dirPath)
  return source:fetchAll({ path = id .. ".yml" })
end

function M:update(config, id, data)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for YamlDirectoryDataSource",
               dirPath))
  end
  local source  = YamlDataSource({}, dirPath)
  return source:replace({ path = id .. ".yml" }, data)

end
return M;
