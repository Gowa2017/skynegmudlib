package.path = package.path .. ";./lualib/?.lua;./lualib/?/init.lua"
package.cpath = package.cpath .. ";./luaclib/?.so"
local yaml    = require("lyaml")
local pretty  = require("pl.pretty")

local file    = ...
local outfile = file:gsub("%.yml", ".lua")
local function convert(path)
  local f   = assert(io.open(path, "r"), "")
  local doc = f:read("a")
  return yaml.load(doc)
end

local t       = convert(file)

local f       = io.open(outfile, "w")
f:write("return " .. pretty.write(t))
