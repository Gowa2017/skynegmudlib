local class = require("pl.class")
local function getField(t, k)
  local v = t -- start with the table of globals
  for w in string.gmatch(k, "[%a_][%w_]*") do v = v[w] end
  return v
end

local function setField(t, k, v)
  local base = t
  for w, d in string.gmatch(k, "([%a_][%w_]*)(%.?)") do
    if d == "." then -- not last item
      base[w] = base[w] or {}
      base = base[w]
    else
      base[w] = v
    end
  end
end
---@class Metadatable
---@field setMeta fun(k:string,v:any)
---@field getMeta fun(k:string):any

---create a Class use pl.class which inherited from *base*
---and add some methods.
---@param base Class
---@return Class
local function metadatable(base)
  local cls = class(base)
  function cls:_init() self:super() end
  function cls:setMeta(k, v)
    assert(self.metadata,
           string.format("%s 没有 metadata 属性", cls.__cname))
    local oldvalue = getField(self.metadata, k)
    setField(self.metadata, k, v)
    self:emit("metadataUpdated", k, v, oldvalue)
  end

  function cls:getMeta(k) return getField(self.metadata, k) end

  return cls
end

return metadatable
