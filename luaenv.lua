package.path =
  package.path .. ";3rd/Penlight/lua/?.lua" .. ";lualib/?/init.lua" ..
    ";lualib/?.lua"
package.cpath = package.cpath .. ";luaclib/?.so"
class = require("pl.class")
