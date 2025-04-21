--- @module "fzf-lua.pickers.workspaces"
--- Neorg workspaces picker

local util = require("fzf-lua.util.module")
local fzf = require("fzf-lua")
local neorg = require("neorg.core")
local Path = require("plenary.path")
local pathlib = require("pathlib")
local modules, log = neorg.modules, neorg.log
local dirman = modules.get_module("core.dirman")
if not dirman then
    log.error("core.dirman module not found")
    return
end

--- Generates a previewer for viewing Neorg workspaces.
--- @return table? #Fzf session previewer
local function workspace_previewer()
    local session_previewer = util.fzf.init_previewer()
    if not session_previewer then
        log.error("failed to initialize session previewer")
        return
    end
    session_previewer.parse_entry = function(_, entry_str)
        local ws = dirman.get_workspace(entry_str)
        if not ws then
            log.error("unexpectedly could not get workspace " .. entry_str)
            return
        end
        return {
            path = ws .. "/index.norg",
        }
    end
    return session_previewer
end

--- Irreversibly deletes a workspace.
--- @param ws_name string #The name of the workspace to delete
local function delete_workspace(ws_name)
    local ws = dirman.get_workspace(ws_name)
    if not ws then
        log.error("unexpectedly could not get workspace " .. ws_name)
        return
    end
    local result = os.execute("rm -rf " .. ws)
    if not result then
        log.error("failed to delete workspace " .. ws_name)
    else
        log.info("deleted workspace " .. ws_name)
    end
    if dirman.get_current_workspace()[2] == ws then
        dirman.set_workspace("default")
    end
end

--- @class workspace_config: neorg.integrations.fzf-lua.picker.config
local M = {
    description = "Open Neorg workspaces",
    exec = function(opts)
        local previewer = workspace_previewer()
        if not previewer then
            log.error("failed to create workspace previewer")
            return
        end
        local function display(fzf_cb)
            local ws = dirman.get_workspace_names()
            table.sort(ws, function(a, b)
                return string.lower(a) < string.lower(b)
            end)
            for _, w in ipairs(ws) do
                fzf_cb(w)
            end
            fzf_cb()
        end
        local exec_opts = vim.tbl_deep_extend("force", {
            cwd_prompt = false,
            file_icons = false,
            git_icons = false,
            cwd_header = false,
            previewer = workspace_previewer(),
            header = util.fzf.generate_header(opts, { "select", "create", "delete" }),
            actions = {
                [opts.pickers.keymaps.select] = function(ws_name)
                    vim.cmd("Neorg workspace " .. ws_name[1])
                end,
                [opts.pickers.keymaps.delete] = {
                    function(ws_name)
                        local confirm = vim.fn.confirm(
                            "delete workspace " .. ws_name[1] .. "? (this will delete all files in the workspace)",
                            "&Yes\n&No",
                            2
                        )
                        if confirm == 1 then
                            delete_workspace(ws_name[1])
                        else
                            log.info("aborted deleting workspace " .. ws_name[1])
                        end
                    end,
                    fzf.actions.resume,
                    header = "Delete workspace",
                },
                [opts.pickers.keymaps.create] = function()
                    if not opts.workspace_location then
                        log.error("Must set workspace_location opt to create a workspace")
                        return
                    end
                    local ws_name = vim.fn.input("Workspace name: ", "", "file")
                    if ws_name == "" then
                        return
                    end
                    local ws_loc = pathlib.new(opts.workspace_location) / ws_name
                    if not dirman.add_workspace(ws_name, ws_loc) then
                        log.error("failed to create workspace " .. ws_name)
                        return
                    end
                    log.info("created workspace " .. ws_name)
                    dirman.touch_file("index.norg", ws_name)
                    vim.cmd("Neorg workspace " .. ws_name)
                    dirman.open_file(ws_name, "index.norg")
                end,
            },
        }, opts.pickers.workspaces)
        fzf.fzf_exec(display, exec_opts)
    end,
    subcommand = {
        args = 0,
    },
}

--- Loads on-demand workspaces from the workspace_location.
--- @param ws_loc string #The location of the workspaces
M.load_ondemand_workspaces = function(ws_loc)
    local existing_ws = dirman.get_workspace_names()
    local scan = require("plenary.scandir")
    scan.scan_dir(vim.fn.expand(ws_loc), {
        depth = 1,
        only_dirs = true,
        on_insert = function(dir)
            if not util.table.contains(existing_ws, dir) then
                local full_dir = pathlib.new(dir)
                local index_path = full_dir / "index.norg"
                if index_path:is_file() then
                    dirman.add_workspace(full_dir:basename(), full_dir)
                end
            end
        end,
    })
end

--- Creates a workspace location if it does not exist.
--- @param ws_loc string #The location of the workspace
M.create_workspace_location = function(ws_loc)
    local dir = pathlib.new(ws_loc)
    if not dir:mkdir(pathlib.permission("rwxr-xr-x"), true) then
        log.error("failed to create workspace location " .. ws_loc)
    end
end

return M
