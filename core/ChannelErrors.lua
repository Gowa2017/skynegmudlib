local R = require("core.lib.wrapper")

local M = {}
M.NoPartyError = R.errortype("NoPartyError")
M.NoRecipientError = R.errortype("NoRecipientError")
M.NoMessageError = R.errortype("NoMessageError")
return M
