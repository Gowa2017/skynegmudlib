local Attribute        = require("core.Attribute").Attribute
local AttributeFormula = require("core.Attribute").AttributeFormula
local tablex           = require("pl.tablex")
local sfmt             = string.formt

---属性工厂，负责加载定义，创建属性对象
---@class AttributeFactory :Class
---@field attributes table<string,table<string,any>> # attribute defines, formua is a AttributeFormula instance
local M                = class()

function M:_init() self.attributes = {} end

---@param name string name
---@param base number base
---@param formula AttributeFormula formula
function M:add(name, base, formula, metadata)
  metadata = metadata or {}
  if formula and not formula:is_a(AttributeFormula) then
    error("Formula not instance of AttributeFormula")
  end

  self.attributes[name] = {
    name     = name,
    base     = base,
    formula  = formula,
    metadata = metadata,
  }
end

function M:has(name) return self.attributes[name] and true end

function M:get(name) return self.attributes[name] end

---
---@param name string
---@param delta number
---@return Attribute
function M:create(name, base, delta)
  delta = delta or 0
  if not self:has(name) then
    error(sfmt("No attribute definition found for [%s]", name))
  end

  local def = self.attributes[name]
  return Attribute(name, base or def.base, delta, def.formula, def.metadata)
end

function M:validateAttributes()
  local references = tablex.reduce(function(acc, attribute)
    if not attribute.formula then return acc end
    acc[attribute.name] = attribute.requires
    return acc
  end, tablex.values(self.attributes), {})
  for attrName, _ in pairs(references) do
    local check = self:_checkReferences(attrName, references)
    if type(check) == "table" then
      table.insert(check, attrName)
      local path = table.concat(check, "->")
      error(sfmt("Attribute formula for [%s] has circular dependency [%s]",
                 attrName, path))
    end
  end

end

function M:_checkReferences(attr, references, stack)
  stack = stack or {}
  if tablex.find(stack, attr) then return stack end

  local requires = references[attr]

  if not requires or #requires < 1 then return true end

  for _, reqAttr in ipairs(requires) do
    table.insert(stack, reqAttr)
    local check = self:_checkReferences(reqAttr, references, stack)
    if type(check) == "table" then return check end
  end
  return true
end

return M
