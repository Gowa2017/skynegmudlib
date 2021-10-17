local Logger = require "core.Logger"
---@class Scriptable
---@field hasBehavior fun(name:string):boolean
---@field setupBehaviors fun(manager:EventManager)
---@field getBehavior fun(name:string):EventManager
---create a Class use pl.class which inherited from *base*
---and add some methods.
---@param base Class
---@return Class
local function scriptable(base)
  local cls = class(base)
  function cls:_int(...) self:super(...) end
  function cls:hasBehavior(name) return self.behaviors[name] and true end

  function cls:getBehavior(name) return self.behaviors[name] end

  function cls:setupBehaviors(manager)
    for name, config in pairs(self.behaviors) do
      local behavior = manager:get(name)
      if not behavior then
        Logger.warn("No script found for [....] behavior \"%q\"", name);
        goto continue
      end
      config = config == true and {} or config
      behavior:attach(self, config)
      ::continue::
    end
  end

  return cls
end

return scriptable
