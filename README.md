# Neorg Fzf
An external module to integrate the [fzf-lua](https://github.com/ibhagwan/fzf-lua) plugin with [neorg](https://github.com/nvim-neorg/neorg).

# Dependencies
- [neorg](https://github.com/nvim-neorg/neorg)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) 
- [plenary](https://github.com/nvim-lua/plenary.nvim)
- [Patched Nerd Fonts for icons](https://nerdfonts.com) [Optional]

# Installation and Quickstart
This should be compatible with any plugin manager that is supported by Neorg.

- Using [lazy.nvim](https://github.com/folke/lazy.nvim)  
  ```lua
  return {
    {
      'nvim-neorg/neorg',
      lazy = false,
      version = '*',
      dependencies = {
        "kev-cao/neorg-fzflua",
        "ibhagwan/fzf-lua",
      },
      opts = {
        load = {
          ['external.integrations.fzf-lua'] = {}
        },
      },
      config = true,
    }
  }
  ```

# Configuration
The following configuration options are offered with some defaults:

```lua
{
    pickers = {
        -- Picker-specific Fzf options. See below for more details.
        workspaces = {
            prompt = " Workspaces: ",
        },
        files = {
            prompt = " Files: ",
        },
        -- Keymaps while in picker. See below for more details.
        keymaps = {
            select = "enter",
            create = "ctrl-n",
            delete = "ctrl-x",
        },
    },
    -- Keymaps for launching pickers.
    keymaps = {
        workspaces = "<leader>ow",
        files = "<leader>of",
    },
    -- Set for on-demand workspaces.
    workspace_location = nil,
}
```
> For a full list of picker-specific Fzf options, see the [fzf-lua docs](https://github.com/ibhagwan/fzf-lua/wiki/Advanced#api-basics-fzf_exec).
> Additionally, the picker keymaps do not follow traditional Neovim syntax, please see the [keymap documentation under "actions"](https://github.com/ibhagwan/fzf-lua/wiki/Advanced#api-basics-fzf_exec).

# Features

- Searching workspaces
- Searching files in current workspace
- Creating on-demand workspaces
  - Creates a workspace in the directory designed by `workspace_location`
 
## Roadmap Features
- Searching within a `.norg` document
- Inserting links from search results

If you have any more ideas, please feel free to create an issue or open a PR!

## Known Limitations

- Neorg-fzflua does support deleting workspaces, but because `neorg.core.dirman` does not currently supply a method to remove workspaces, they will continue to show up in the workspace picker until the plugin/Neovim is reloaded.

# Contributing

To create a new picker, create a new file in [`lua/fzf-lua/pickers/`](lua/fzf-lua/pickers). The module should return a picker config, as defined here:

https://github.com/kev-cao/neorg-fzflua/blob/f40a0250dcc3ee7897a8d75084c16a8c8659ab28/lua/neorg/modules/external/integrations/fzf-lua/module.lua#L64-L67

Once you've created your picker extension, register it in [`lua/fzf-lua/neorg.lua`](lua/fzf-lua/neorg.lua) under the same name as its filename. If you have any keymaps you want to add for your picker, go to [lua/neorg/modules/external/integrations/fzf-lua/module.lua](lua/neorg/modules/external/integrations/fzf-lua/module.lua#L25-L62) and add it to the public config with some sensible defaults.

Please try to use [type annotations](https://luals.github.io/wiki/annotations/) wherever possible to make future development easy. Also follow the style guide defined in [stylua.toml](./stylua.toml) using [Stylua](https://github.com/JohnnyMorganz/StyLua).

# License
All files in this repository without annotation are licensed under the *GPL-3.0 license* as detailed in [LICENSE](./LICENSE).
