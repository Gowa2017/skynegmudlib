local path           = require("pl.path")
local fs             = require("pl.file")
local sfmt           = string.format

local FileDataSource = require("core.DataSource.FileDataSource")
local lyaml          = require("lyaml")

---@class YamlDataSource : FileDataSource
local M              = class(FileDataSource)

function M:hasData(config)
  config = config or {}
  local filepath = self:resolvePath(config)
  return path.exists(filepath)
end
function M:fetchAll(config)
  config = config or {}
  local filepath = self:resolvePath(config)
  if not self:hasData(config) then
    error(sfmt("Invalid path [%q] for YamlDataSource", filepath))
  end

  local f        = assert(io.open(filepath, "r"), sfmt(
                            "Open file [%q] error for YamlDataSource", filepath))
  local stream   = f:read("a")
  f:close()
  return lyaml.load(stream)

end
function M:fetch(config, id)
  config = config or {}
  local data = self:fetchAll(config)

  if not rawget(data, id) then error(sfmt("Record with id [%q] not found", id)) end

  return data[id]
end

function M:replace(config, data)
  config = config or {}
  local filepath = self:resolvePath(config)
  return fs.write(filepath, lyaml.dump(data))
end
function M:update(config, id, data)
  config = config or {}
  local currentData = self:fetchAll(config)
  currentData[id] = data
  self:replace(config, currentData)
end
return M
