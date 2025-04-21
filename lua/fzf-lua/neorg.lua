--- @module "fzf-lua.neorg"
--- Exports all available pickers for Neorg

--- @type table<string, neorg.integrations.fzf-lua.picker.config>
local M = {
    workspaces = require("fzf-lua.pickers.workspaces"),
    files = require("fzf-lua.pickers.files"),
}

return M
