--- @module "fzf-lua.util.fzf"
--- Utility functions for fzf-lua

local M = {}
local log = require("neorg.core.log")

M.init_previewer = function()
    local builtin_ok, builtin = pcall(require, "fzf-lua.previewer.builtin")
    if not builtin_ok then
        log.error("failed to load fzf-lua.previewer.builtin")
    end

    local session_previewer = builtin.buffer_or_file:extend()

    session_previewer.new = function(self, o, opts, fzf_win)
        session_previewer.super.new(self, o, opts, fzf_win)
        setmetatable(self, session_previewer)
        return self
    end

    session_previewer.gen_winopts = function(self)
        local new_winopts = {
            wrap = false,
            number = false,
        }
        return vim.tbl_extend("force", self.winopts, new_winopts)
    end

    return session_previewer
end

--- Generates a default header for the fzf-lua picker.
--- @param opts neorg.integrations.fzf-lua.opts #The options for the fzf-lua picker
--- @param actions table<number, "select"|"create"|"delete"> #The actions to be displayed in the header
--- @return string #The generated header string
M.generate_header = function(opts, actions)
    local header = {}
    for _, action in ipairs(actions) do
        local keymap = opts.pickers.keymaps[action]
        if keymap then
            table.insert(header, "<" .. keymap .. ">: " .. action)
        end
    end
    return table.concat(header, " | ")
end

return M
