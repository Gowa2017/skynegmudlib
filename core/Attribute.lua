local class = require("pl.class")
---当我们进行属性定义的时候，最少应该定义：name,label, base
---metadata 与 formula 为可选
---@class Attribute : Class
---@field name string
---@field base number
---@field delta number
---@field formula AttributeFormula | nil
---@field metadata table
local M     = class()
---@return Attribute
function M:_init(name, base, delta, formula, metadata)
  self.name = name
  self.base = base
  self.delta = delta or 0
  if formula then self.formula = formula end
  self.metadata = metadata or {}
end

function M:lower(amount) self:raise(-amount) end

function M:raise(amount) self.delta = math.min(0, self.delta + amount) end

function M:setBase(amount) self.base = math.max(amount, 0) end

function M:setDelta(amount) self.delta = math.min(0, amount) end

function M:serialze() return { delta = self.delta, base  = self.base } end

---@class AttributeFormula : Class
---@field requires string[]
---@field formula fun(character:Character, currentVal:number,...)
local F     = class()

---@param requires string[]
---@param fn fun(...)
function F:_init(requires, fn)
  self.requires = requires
  self.formula = fn
end

---每个属性的 formula 函数都是 这样 fun(character, currentVal, ...)
---每个属性只会有一个 Formula 所以要注意执行的环境
---这个函数最终会由 Character 绑定到其他对象上去执行
---@vararg any # character, currentVal,...
function F:evaluate(...) return self.formula.formula(...) end

return { Attribute        = M, AttributeFormula = F }
