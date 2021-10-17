local sfmt = string.format

---@class EntityLoader: Class
---@field dataSource DataSource
---@field config? table
local M    = class()

function M:_init(dataSource, config)
  self.dataSource = dataSource
  self.config = config or {}
end

function M:setArea(name) self.config.area = name end

function M:setBundle(name) self.config.bundle = name end

function M:hasData() return self.dataSource:hasData(self.config) end

function M:fetchAll()
  if not self.dataSource["fetchAll"] then
    error(sfmt("fetchAll not supported by %s", self.dataSource.name))
  end
  return self.dataSource:fetchAll(self.config)
end

function M:fetch(id)
  assert(self.dataSource["fetch"],
         sfmt("fetch not supported by %s", self.dataSource.name))
  return self.dataSource:fetch(self.config, id)

end

function M:replace(data)
  assert(self.dataSource["replace"],
         sfmt("replace not supported by %s", self.dataSource.name))
  return self.dataSource:replace(self.config, data)

end

function M:update(id, data)
  assert(self.dataSource["update"],
         sfmt("update not supported by %s", self.dataSource.name))
  return self.dataSource:update(self.config, id, data)

end

return M
