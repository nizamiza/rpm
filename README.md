# 📦 RPM - A Rudimentary Plugin Manager

RPM is a rudimentary plugin manager for NeoVim. It is designed to be simple and
easy to use.

## Installation

1. Clone the repository into your `~/.config/nvim/pack/plugins/start` directory:

```sh
git clone https://github.com/nizamiza/rpm.git ~/.config/nvim/pack/plugins/start/rpm
```

2. Create `rpm.lua` in your `~/.config/nvim/lua/plugins/` directory:

```lua
-- lua/plugins/rpm.lua
return {
  "nizamiza/rpm",
}
```

> This is required so that RPM doesn't remove itself when you run `:Rpm clean`.

3. Require the plugin in your `init.lua`:

```lua
require("rpm")
```

4. Restart NeoVim!

## Usage

1. Define your plugins in `lua/plugins/` directory of your NeoVim configuration
   directory. The file should correspond to the plugin name. Avoid any extra
   extensions in the file name (`.vim`, `.nvim`, etc). For example, if you want
   to install `nvim-telescope/telescope.nvim`, you would create a file called
   `telescope.lua` in the `lua/plugins/` directory:

    ```lua
    -- lua/plugins/telescope.lua
    return {
      "nvim-telescope/telescope.nvim",
      function()
        require("telescope").setup({
          defaults = {
            layout_strategy = "vertical",
          },
        })
      end
    }
    ```

    The first element in the table is the plugin name. Either specify a full URL
    to the repository or a shorthand name if it is available on GitHub.

    The second element is an optional function that will be called after the
    plugin is loaded. This is useful for calling the setup function for the
    plugin, setting up keybindings, etc.

    Restart NeoVim after adding or modifying a plugin definition.

2. Telescope has a dependency on `plenary.nvim`. To define a plugin dependency,
   you can pass a table as the first element in the plugin definition. Make sure
   that the main plugin is the last element in the table. For example:

    ```lua
    -- lua/plugins/telescope.lua
    return {
      {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
      },
      function()
        require("telescope").setup({
          defaults = {
            layout_strategy = "vertical",
          },
        })
      end
    }
    ```

    You can use this to define dependencies or just to group plugins together.
    But remember that only the last plugin is treated as the "main" plugin.
    Others will not show up when you run `:Rpm list`.

3. Run `:Rpm install <plugin-name>` to install a plugin and its dependencies.
   This will clone the repositories into the
   `~/.config/nvim/pack/plugins/start/` directory and then run the setup
   function for each plugin.

4. Alternatively, run `:Rpm install_all` to install all plugins in the
   `lua/plugins/` directory.

5. Run `:Rpm list` to see a list of installed plugins.

6. Run `:Rpm update` to update a specific plugin.

7. Run `:Rpm update_all` to update all plugins.

8. Run `:Rpm clean` to remove all plugins that are not defined in the
   `lua/plugins/` directory.

9. Run `:Rpm delete` to remove a specific plugin.

10. Run `:Rpm delete_all` to remove all plugins.

## Remarks

RPM is indeed a rudimentary plugin manager. It is not designed to be a
full-featured plugin manager like `vim-plug` or `packer.nvim`. If you seek more
advanced features, consider alternatives.

## License

This project is licensed under the Apache License, Version 2.0. See
[LICENSE](LICENSE) for more information.
