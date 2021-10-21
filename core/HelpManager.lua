local class  = require("pl.class")
---@class HelpManager
local M      = class()
local tablex = require "pl.tablex"
function M:_init() self.helps = {} end

function M:get(help) return self.helps[help] end

function M:add(help) self.helps[help.name] = help end

function M:find(search)
  local results = {}
  for name, help in pairs(self.helps) do
    local s, _ = name:find(search)
    if s == 1 then
      results[name] = help
      goto continue
    end
    for _, keyword in ipairs(help.keywords) do
      if keyword:find(search) then
        results[name] = help
        break
      end
    end
    ::continue::
  end
  return results
end

function M:getFirst(help)
  local results = self:find(help)
  if tablex.size(results) < 1 then return end
  return tablex.values(results)[1]
end

return M
