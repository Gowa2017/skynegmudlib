local class             = require("pl.class")
local path              = require("pl.path")
local dir               = require("pl.dir")

local sfmt              = string.format
local tconcat           = table.concat

local FileDataSource    = require("core.DataSource.FileDataSource")
local LuaDataSource     = require("core.DataSource.LuaDataSource")

---
---Data source for areas stored in lua. Looks for a directory structure like:
---
---  path/
---    area-one/
---      manifest.lua
---    area-two/
---      manifest.lua
---
---Config:
---  path: string: relative path to directory containing area folders
---
---
---@class LuaAreaDataSource : FileDataSource
local LuaAreaDataSource = class(FileDataSource)

function LuaAreaDataSource:hasData(config)
  config = config or {}
  local dirPath = self:resolvePath(config)
  return path.exists(dirPath)
end

function LuaAreaDataSource:fetchAll(config)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not self:hasData(config) then
    error(sfmt("Invalid path [%q] sepecified for LuaAreaDataSource", dirPath))
  end
  local res     = {}
  local dirs    = dir.getdirectories(dirPath)
  for _, fullPath in ipairs(dirs) do
    local _, DIR       = path.splitpath(fullPath)
    if not path.isdir(fullPath) then goto continue end
    local manifestPath = tconcat({ dirPath, DIR, "manifest.lua" }, "/")
    if not path.exists(manifestPath) then goto continue end
    res[DIR] = self:fetch(config, DIR)
    ::continue::
  end
  return res

end

function LuaAreaDataSource:fetch(config, id)
  config = config or config
  local dirPath = self:resolvePath(config)
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for LuaAreaDataSource", dirPath))
  end
  local source  = LuaDataSource({}, dirPath)
  return source:fetchAll({ path = tconcat({ id, "manifest.lua" }, "/") })

end

function LuaAreaDataSource:update(config, id, data)
  config = config or {}
  local dirPath = self:resolvePath(config)
  if not path.exists(dirPath) then
    error(sfmt("Invalid path [%q] sepecified for LuaAreaDataSource", dirPath))
  end
  local source  = LuaDataSource({}, dirPath)
  return source:replace({ path = tconcat({ id, "manifest.lua" }, "/") }, data)

end

return LuaAreaDataSource
