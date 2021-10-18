local class           = require("pl.class")
local sfmt            = string.format
local BehaviorManager = require("core.BehaviorManager")

---@class EntityFactory : Class
---@field entitys table<string,table> # defines
---@field scripts BehaviorManager
local M               = class()

function M:_init()
  self.entitys = {}
  self.scripts = BehaviorManager()
end

---@param area string
---@param id string
---@return string @area:id
function M:createEntityRef(area, id) return area .. ":" .. id end

---@param entityRef string
---@return table
function M:getDefinition(entityRef) return self.entitys[entityRef] end

---@param entityRef string
---@param def table
function M:setDefinition(entityRef, def)
  def.entityReference = entityRef
  self.entitys[entityRef] = def
end

---@param entityRef string
---@param event string
---@param listener function
function M:addScriptListener(entityRef, event, listener)
  self.scripts:addListener(entityRef, event, listener)
end

---@param area Area
---@param entityRef string
---@param Type Class
---@return table @object of type Type
function M:createByType(area, entityRef, Type)
  local def    = self:getDefinition(entityRef)
  assert(def, sfmt("No Entity definition found for [%q]", entityRef))
  local entity = Type(area, def)
  if self.scripts[entityRef] then self.scripts[entityRef]:attach(entity) end
  return entity
end

function M:create() assert(false, "no type") end

function M:clone(entity) return self:create(entity.area, entity.entityReference) end

return M
