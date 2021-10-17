local class   = require("pl.class")
local Account = require("core.Account")
---@class AccountManager : Class
---@field accounts table<string,Account> # username, Account pairs
---@field loader EntityLoader
local M       = class()

function M:_init()
  self.accounts = {}
  self.loader = false
end

function M:setLoader(loader) self.loader = loader end

function M:addAccount(acc) self.accounts[acc.username] = acc end

function M:getAccount(username) return self.accounts[username] end

function M:loadAccount(username, force)
  if not force and self.accounts[username] then
    return self:getAccount(username)
  end

  if not self.loader then error("No entity loader configured for accounts") end
  local data    = self.loader:fetch(username)
  local account = Account(data)
  self:addAccount(account)
  return account
end

return M
