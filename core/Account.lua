local Data = require("core.Data")

---@class Account : Class
---@field username string
---@field password string
---@field characters table<string,boolean>
---@field banned boolean
---@field deleted boolean
---@field metadata table<any,any>
local M    = class()

---@param data table
function M:_init(data)
  self.username = data.username
  self.characters = data.characters or {}
  self.password = data.password
  self.banned = data.banned or false
  self.deleted = data.deleted or false
  self.metadata = data.metadata or {}
end

function M:getUsername() return self.username end

function M:addCharacter(username)
  self.characters[username] = { username = username, deleted  = false }
end

function M:hasCharacter(name) return self.characters[name] and true end

---@param name string
function M:deleteCharacter(name)
  self.characters[name].deleted = true
  self:save()
end

---@param name string
function M:undeleteCharacter(name)
  self.characters[name].deleted = false
  self:save()
end

---@param pass string
function M:setPassword(pass)
  self.password = self:_hashPassword(pass)
  self.save()
end

-- TODO
function M:checkPassword(pass) return pass == self.password end

function M:save(callback)
  Data.save("account", self.username, self:serialize(), callback)
end

function M:ban()
  self.banned = true
  self:save()
end

function M:deleteAccount()
  for _, char in pairs(self.characters) do self:deleteCharacter(char.username) end
  self.deleted = true
  self:save()
end

function M:_hashPassword(pass) return pass end

function M:serialize()
  return {
    username   = self.username,
    characters = self.characters,
    password   = self.password,
    metadata   = self.metadata,
    deleted    = self.deleted,
    banned     = self.banned,
  }
end

return M
