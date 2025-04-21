--- @module "fzf-lua.pickers.files"
--- Neorg files picker

local util = require("fzf-lua.util.module")
local fzf = require("fzf-lua")
local neorg = require("neorg.core")
local modules, log = neorg.modules, neorg.log
local dirman = modules.get_module("core.dirman")
if not dirman then
    log.error("core.dirman module not found")
    return
end

--- Generates a previewer for viewing files in a Neorg workspace.
--- @param ws table #The workspace to preview files from
--- @return table? #Fzf session previewer
local function file_previewer(ws)
    local session_previewer = util.fzf.init_previewer()
    if not session_previewer then
        log.error("Error initializing session previewer")
        return
    end
    --- @param entry_str string #The entry string to be previewed
    session_previewer.parse_entry = function(_, entry_str)
        return {
            path = ws[2] .. "/" .. entry_str,
        }
    end

    return session_previewer
end

--- Prompts the user to create a new file in the current workspace.
local function prompt_create_file_in_ws()
    local fname = vim.fn.input("File name: ", "", "file")
    if fname == "" then
        return
    end
    local ws = dirman.get_current_workspace()
    dirman.create_file(fname, ws[1], {})
end

--- @type neorg.integrations.fzf-lua.picker.config
local M = {
    description = "Open files in the current workspace",
    --- Lists files in the current workspace using fzf.
    exec = function(opts)
        local ws = dirman.get_current_workspace()
        local exec_opts = vim.tbl_deep_extend("force", {
            cwd_prompt = false,
            file_icons = false,
            git_icons = false,
            cwd_header = false,
            previewer = file_previewer(ws),
            header = util.fzf.generate_header(opts, { "select", "create", "delete" }),
            actions = {
                [opts.pickers.keymaps.select] = function(file)
                    dirman.open_file(ws[1], file[1])
                end,
                [opts.pickers.keymaps.delete] = {
                    function(file)
                        local confirm = vim.fn.confirm("delete file?", "&Yes\n&No", 2)
                        if confirm == 1 then
                            local full_path = ws[2] / file[1]
                            local success
                            full_path:unlink()
                            if not success then
                                vim.notify("Failed to delete file: " .. file[1], vim.log.levels.ERROR)
                            else
                                vim.notify("Deleted file: " .. file[1], vim.log.levels.INFO)
                            end
                        end
                    end,
                    fzf.actions.resume,
                    header = "Delete file",
                },
                [opts.pickers.keymaps.create] = function()
                    prompt_create_file_in_ws()
                end,
            },
        }, opts.pickers.files)
        -- We use `find` instead of `dirman.get_norg_files` because the latter
        -- suffers from performance issues when in a directory with many files.
        fzf.fzf_exec("cd " .. ws[2] .. " && find * -iname '*.norg'", exec_opts)
    end,
    subcommand = {
        args = 0,
    },
}

return M
