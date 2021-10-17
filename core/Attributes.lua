---属性对象的容器
---@class Attributes :Class
---@field attributes table<string,Attribute>
local M = class()

function M:_init() self.attributes = {} end
---@param attribute Attribute
function M:add(attribute) self.attributes[attribute.name] = attribute end

function M:has(attr) return self.attributes[attr] and true end

function M:get(attr) return self.attributes[attr] end

function M:getAttributes() return self.attributes end

function M:clearDelta() for _, v in pairs(self.attributes) do v:setDelta(0) end end

function M:serialize()
  local data = {}
  for k, v in pairs(self.attributes) do data[k] = v:serialze() end
  return data
end
return M
