--- @module fzf-lua.util.table
--- Utility functions for tables

local M = {}

--- Check if a table contains a value
--- @param t table The table to check
--- @param value any The value to check for
--- @return boolean True if the value is found in the table, false otherwise
M.contains = function(t, value)
    for _, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

return M
