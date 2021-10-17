local path                   = require("pl.path")
local dir                    = require("pl.dir")
local sfmt                   = string.format
local tconcat                = table.concat

local FileDataSource         = require("core.DataSource.FileDataSource")
local LuaDataSource          = require("core.DataSource.LuaDataSource")

--- Data source when you have a directory of yaml files and each entity is stored in
--- its own lua file, e.g.,
---
---   foo/
---     a.lua
---     b.lua
---     c.lua
---
--- Config:
---   path: string: relative path to directory containing .lua files from project root
---
---
---@class LuaDirectoryDataSource : FileDataSource
local LuaDirectoryDataSource = class(FileDataSource)

function LuaDirectoryDataSource:hasData(config)
  config = config or {}
  local filePath = self:resolvePath(config)
  return path.exists(filePath)

end

function LuaDirectoryDataSource:fetchAll(config)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not self:hasData(config) then
    error(
      sfmt("Invalid path [%q] specified for LuaDirectoryDataSource", dirPath))
  end
  local files   = dir.getallfiles(dirPath)
  local res     = {}
  for _, file in ipairs(files) do
    if path.extension(file) ~= ".lua" then goto continue end
    local id = path.basename(file):sub(1, -4)
    res[id] = self:fetch(config, id)
    ::continue::
  end
  return res

end

function LuaDirectoryDataSource:fetch(config, id)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for LuaDirectoryDataSource",
               dirPath))
  end
  local source  = LuaDataSource({}, dirPath)
  return source:fetchAll({ path = tconcat({ id, ".lua" }, "") })
end

function LuaDirectoryDataSource:update(config, id, data)
  local dirPath = self:resolvePath(config)
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for LuaDirectoryDataSource",
               dirPath))
  end
  local source  = LuaDataSource({}, dirPath)
  return source:replace({ path = tconcat({ id, ".lua" }, "") }, data)

end

return LuaDirectoryDataSource
