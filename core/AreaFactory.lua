local class         = require("pl.class")
local sfmt          = string.format

local Area          = require("core.Area")
local EntityFactory = require("core.EntityFactory")

---@class AreaFactory : EntityFactory
local M             = class(EntityFactory)

---@param entityRef string areaName
---@return Area
function M:create(entityRef)
  local definition = self:getDefinition(entityRef)
  assert(definition, sfmt("No entity definition found for %s", entityRef))
  local area       = Area(definition.bundle, entityRef, definition.manifest)
  if self.scripts:has(entityRef) then self.scripts:get(entityRef):attach(area) end
  return area
end

---@param area Area
---@return Area
function M:clone(area) return self:create(area.name) end

return M
