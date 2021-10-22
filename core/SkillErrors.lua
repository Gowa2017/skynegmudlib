local R = require("core.lib.wrapper")
local M = {}
M.NotEnoughResourcesError = R.errortype("NotEnoughResourcesError")
M.PassiveError = R.errortype("PassiveError")
M.CooldownError = R.errortype("CooldownError")
return M
