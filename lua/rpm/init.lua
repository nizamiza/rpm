local core = require("rpm.core")
local plugin_list = require("rpm.plugin_list")

local function init_plugins()
  print("Initializing plugins...")

  for _, plugin in pairs(plugin_list) do
    local routine = coroutine.create(function()
      if core.is_plugin_installed(plugin.path) and plugin.init_fn then
        plugin.init_fn()
      end
    end)

    coroutine.resume(routine)
  end
end

local init_routine = coroutine.create(init_plugins)

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  desc = "Fetch plugins",
  callback = function()
    coroutine.resume(init_routine)
  end
})

