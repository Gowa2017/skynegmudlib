---@class Config
local M = class()

local config = {}

function M.get(k, fallback) return config[k] and config[k] or fallback end

function M.load(data) config = data end

return M
