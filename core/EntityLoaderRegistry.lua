local sfmt         = string.format
local EntityLoader = require("core.EntityLoader");
---@class EntityLoaderRegistry : Class
---@field loaders table<string,EntityLoader>
local M            = class()

function M:_init() self.loaders = {} end

function M:load(sourceRegistry, config)
  config = config or {}
  for name, settings in pairs(config) do
    if not settings.source then
      error(sfmt("EntityLoader [%q] does not specify a source", name))
    end
    if type(settings.source) ~= "string" then
      error(sfmt("EntityLoader [%q] has an invalid source", name))
    end
    local source       = sourceRegistry:get(settings.source)
    if not source then
      error(sfmt("Invalid source [%q] for entity [%q]", settings.source, name))
    end

    local sourceConfig = settings.config or {}
    self.loaders[name] = EntityLoader(sourceRegistry:get(settings.source),
                                      sourceConfig)
  end
end

---@return EntityLoader
function M:get(name) return self.loaders[name] end

return M
