local eansi = require("eansi")
local tag   = "%b<>"
eansi._colortag = tag

eansi.register({})
local s     =
  "<bold red>My <bold_off green>colorful ${italic blue on_grey3}string"
print(eansi(s))
