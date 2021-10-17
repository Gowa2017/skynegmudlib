local path           = require("pl.path")
local file           = require("pl.file")
local pretty         = require("pl.pretty")
local sfmt           = string.format
local tconcat        = table.concat
local FileDataSource = require("core.DataSource.FileDataSource")

---Data source when you have all entities in a single lua file
---@class LuaDataSource : FileDataSource
local LuaDataSource  = class(FileDataSource)

function LuaDataSource:_init(config, rootPath)
  self:super(config, rootPath)
  self.cache = {}
end

function LuaDataSource:hasData(config)
  config = config or {}
  local filePath = self:resolvePath(config)
  return path.exists(filePath)

end

function LuaDataSource:fetchAll(config)
  config = config or {}
  local filePath = self:resolvePath(config)
  if not self:hasData(config) then
    error(sfmt("Invalid path [%q] for LuaDataSource", filePath))
  end
  self.cache[filePath] = loadfile(filePath, "bt")()
  return self.cache[filePath]

end

function LuaDataSource:fetch(config, id)
  config = config or {}
  local data = self:fetchAll(config)
  if not rawget(data, "id") then
    error(sfmt("Record with id [%q] not found", id))
  end
  return data[id]

end

function LuaDataSource:replace(config, data)
  local filePath = self:resolvePath(config)
  return file.write(filePath,
                    tconcat({ "return", pretty.write(data, "  ", true) }, " "))
end

function LuaDataSource:update(config, id, data)
  config = config or {}
  local currentData = self:fetchAll(config)
  currentData[id] = data
  return self:replace(config, currentData)

end

return LuaDataSource
