local Interface = require("rpm.interface")
local Core = require("rpm.core")
local Plugins = require("rpm.plugins")

local function after_init()
  vim.notify("Plugins initialized.")

  Interface._.after_init(Plugins)

  if Interface.after_init then
    Interface.after_init(Plugins)
  end
end

local INIT_INTERVAL = 100

local function init_plugins()
  vim.wait(INIT_INTERVAL, function()
    if Plugins._.loaded then
      return false
    end

    vim.notify("Initializing " .. Plugins._.count .. " plugins.")
    local initialized_count = 0

    for _, plugin in pairs(Plugins) do
      vim.schedule(function()
        if Core.is_plugin_installed(plugin.path) and plugin.init_fn then
          plugin.init_fn()
          plugin.initialized = true
        end

        initialized_count = initialized_count + 1

        if initialized_count == Plugins._.count then
          vim.schedule(after_init)
        end
      end)
    end

    return true
  end, INIT_INTERVAL)
end

local rpm_augroup = vim.api.nvim_create_augroup("rpm", {})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  desc = "Fetch plugins",
  group = rpm_augroup,
  callback = function()
    vim.schedule(init_plugins)
  end
})
