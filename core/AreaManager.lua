local class           = require("pl.class")
local BehaviorManager = require("core.BehaviorManager")
local Area            = require("core.Area")
local Room            = require("core.Room")

---@class AreaManager : Class
---@field areas table<string,Area> # areaName,Area pairs
---@field scripts BehaviorManager
local M               = class()

function M:_init()
  self.areas = {}
  self.scripts = BehaviorManager()
end

function M:getArea(name) return self.areas[name] end

function M:getAreaByReference(entityRef)
  local _, name = entityRef:find("(.*):.*")
  return self:getArea(name)

end

function M:addArea(area) self.areas[area.name] = area end

function M:removeArea(area) self.areas[area.name] = nil end

function M:tickAll(state)
  for name, area in pairs(self.areas) do area:emit("updateTick", state) end
end

function M:getPlaceholderArea()
  if self._placeholder then return self._placeholder end
  self._placeholder = Area(nil, "placeholder", { title = "Placeholder" })
  local placeholderRoom = Room(self._placeholder, {
    id          = "placeholder",
    title       = "Placeholder",
    description = "You are not in a valid room. Please contact an administrator",
  })

  self._placeholder:addRoom(placeholderRoom)
  return self._placeholder
end

return M
