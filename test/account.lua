local pretty  = require("pl.pretty")
local test    = require("pl.test")

local Account = require("core.Account")

---@type Account
local acc     = Account({ username = "test", password = "wouinibaba" })
acc:addCharacter("char1")

test.asserteq(acc:getUsername(), "test")
test.asserteq({
  username   = "test",
  password   = "wouinibaba",
  banned     = false,
  deleted    = false,
  characters = { char1 = { username = "char1", deleted  = false } },
  metadata   = {},
}, acc:serialize())
