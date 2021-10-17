local class = require("pl.class")
local sfmt  = string.format
---@class Helpfile : Class
local M     = class()

function M:_init(bundle, name, options)
  self.bundle = bundle;
  self.name = name;

  if not options or not options.body then
    error(sfmt("Help file [%s] has no content", name))
  end

  self.keywords = options.keywords or { name };
  self.command = options.command;
  self.channel = options.channel;
  self.related = options.related or {};
  self.body = options.body;
end

return M
