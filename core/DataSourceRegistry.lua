local class = require("pl.class")
local sfmt  = string.format

---@class DataSource
---@field hasData fun(config?:table):boolean #Returns whether or not there is data for a given config.
---@field fetch fun(config?:table,id:any) #Gets a specific record by id for a given config
---@field fetchAll fun() #Returns all entries for a given config.
---@field update fun(config?:table,id:any,data:any) #Update specific record. Write version of `fetch`
---@field replace fun(config?:table,data:any) #Perform a full replace of all data for a given config.
---@field name string # to load which source

---@class DataSourceRegistry : Class
---@field sources table<string, DataSource>
local M     = class()

function M:_init() self.sources = {} end

function M:load(requireFn, rootPath, config)
  config = config or {}
  for name, settings in pairs(config) do
    if not settings.require then
      error(sfmt("DataSource [%s] does not specify a \"require\"", name))
    end
    if type(settings.require) ~= "string" then
      error(sfmt("DataSource [%s] has an invalid \"require\"", name))
    end
    local sourceConfig = settings.config or {}
    local loader      
    if settings.require[0] == "." then
      loader = require(rootPath + "/" + settings.require)
    else
      if not settings.require:find(".") then
        loader = require(settings.require)
      else
        -- local moduleName, exportName = table.unpack(stringx.split(
        --                                               settings.require, "."))
        -- loader = requireFn(moduleName)[exportName]
        loader = requireFn(settings.require)
      end
      local instance = loader(sourceConfig, rootPath)
      if not instance.hasData then
        error(sfmt(
                "Data Source %s requires at minimum a \"hasData(config): boolean\" method",
                name))
      end
      instance.name = name
      self.sources[name] = instance
    end
  end
end

---@return DataSource
function M:get(name) return self.sources[name] end

return M
