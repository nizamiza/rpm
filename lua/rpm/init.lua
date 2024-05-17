local Interface = require("rpm.interface")
local Core = require("rpm.core")
local Plugins = require("rpm.plugins")
local Constants = require("rpm.constants")
local UI = require("rpm.ui")

local M = Interface

---@return nil
local function after_init_plugins()
  UI.notify("Plugins initialized.")

  if Interface.after_init then
    Interface.after_init()
  end
end

---@return nil
local function init_plugins()
  Plugins.load({
    on_complete = function(plugin_list)
      UI.notify("Initializing " .. Plugins.count .. " plugins.")
      local initialized_count = 0

      for _, plugin in pairs(plugin_list) do
        vim.schedule(function()
          if Core.is_plugin_installed(plugin.path) and plugin.init_fn then
            plugin.init_fn()
            plugin.initialized = true
          end

          initialized_count = initialized_count + 1

          if initialized_count == Plugins.count then
            vim.schedule(after_init_plugins)
          end
        end)
      end
    end
  })
end

local rpm_augroup = vim.api.nvim_create_augroup(Constants.PLUGIN_NAME, {})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  desc = "Load and initialize plugins",
  group = rpm_augroup,
  callback = function()
    vim.schedule(init_plugins)
  end
})

return M
