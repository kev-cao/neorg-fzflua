local neorg = require("neorg.core")
local modules, log = neorg.modules, neorg.log
local module = modules.create("external.integrations.fzf-lua")

module.setup = function()
    local required = {
        "fzf-lua",
        "plenary",
    }
    for _, mod in ipairs(required) do
        local ok, _ = pcall(require, mod)
        if not ok then
            log.error("integrations.fzf-lua requires " .. mod .. " to be loaded")
            return {
                success = false,
            }
        end
    end
    return {
        success = true,
        requires = { "core.dirman", "core.neorgcmd" },
    }
end

--- @class neorg.integrations.fzf-lua.opts.pickers
--- @field workspaces neorg.integrations.fzf-lua.opts.pickers.picker_opts? Options for the workspaces picker
--- @field files neorg.integrations.fzf-lua.opts.pickers.picker_opts? Options for the files picker
--- @field keymaps neorg.integrations.fzf-lua.opts.pickers.keymaps? Keymaps within an fzf window

--- @class neorg.integrations.fzf-lua.opts.pickers.picker_opts
--- @field prompt string? The prompt to show when selecting workspaces
--- @field header string? The header to show when selecting workspaces

--- @class neorg.integrations.fzf-lua.opts.pickers.keymaps
--- @field select string? The keymap to use when selecting a resource in a picker
--- @field create string? The keymap to use when creating a resource in a picker
--- @field delete string? The keymap to use when deleting a resource in a picker

--- @class neorg.integrations.fzf-lua.opts
--- @field pickers neorg.integrations.fzf-lua.opts.pickers? Options for the pickers
--- @field keymaps table<string, string>? Keymaps for opening pickers
--- @field workspace_location string|nil? The directory where workspaces should be created
module.config.public = {
    pickers = {
        workspaces = {
            prompt = " Workspaces: ",
        },
        files = {
            prompt = " Files: ",
        },
        keymaps = {
            select = "enter",
            create = "ctrl-n",
            delete = "ctrl-x",
        },
    },
    keymaps = {
        workspaces = "<leader>ow",
        files = "<leader>of",
    },
    workspace_location = nil,
}

--- @class neorg.integrations.fzf-lua.picker.config
--- @field exec fun(opts: neorg.integrations.fzf-lua.opts) The function to execute when the picker is called.
--- @field description string The description of the picker.
--- @field subcommand table? Neorg subcommand registration options. Name will be auto-generated. If not provided, will not create a subcommand.

module.load = function()
    local picker_configs = require("fzf-lua.neorg")
    local handlers = {}
    local subcommands = {}
    for name, picker in pairs(picker_configs) do
        handlers["external.integrations.fzf-lua." .. name] = picker.exec
        if picker.subcommand then
            picker.subcommand.name = "external.integrations.fzf-lua." .. name
            subcommands[name] = picker.subcommand
        end
    end

    modules.await("core.neorgcmd", function(neorgcmd)
        neorgcmd.add_commands_from_table({
            fzf = {
                name = "external.integrations.fzf-lua.fzf",
                args = 1,
                subcommands = subcommands,
            },
        })
    end)

    -- Assign handlers for :Neorg fzf commands.
    module.on_event = function(event)
        local ev_name = event.split_type[2]
        if handlers[ev_name] then
            handlers[ev_name](module.config.public)
        else
            log.error("No handler for event " .. ev_name)
        end
    end

    -- Assign keymaps for pickers.
    for name, keymap in pairs(module.config.public.keymaps) do
        local picker = picker_configs[name]
        vim.keymap.set("n", keymap, function()
            picker.exec(module.config.public)
        end, { desc = picker.description })
    end

    local ws_loc = module.config.public.workspace_location
    if ws_loc then
        local workspaces = require("fzf-lua.pickers.workspaces")
        workspaces.create_workspace_location(ws_loc)
        workspaces.load_ondemand_workspaces(ws_loc)
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["external.integrations.fzf-lua.workspaces"] = true,
        ["external.integrations.fzf-lua.files"] = true,
    },
}

return module
