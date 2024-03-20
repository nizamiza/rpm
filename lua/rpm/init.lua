local core = require("rpm.core")
local plugin_list = require("rpm.plugin_list")

local function init_plugins()
  print("Initializing plugins...")

  local routines = {}

  for _, plugin in pairs(plugin_list) do
    local routine = coroutine.create(function()
      if core.is_plugin_installed(plugin.path) and plugin.init_fn then
        plugin.init_fn()
      end
    end)

    coroutine.resume(routine)
    table.insert(routines, routine)
  end

  vim.wait(100, function()
    for _, routine in pairs(routines) do
      if coroutine.status(routine) ~= "dead" then
        return false
      end
    end

    print("Plugins initialized.")
    return true
  end)
end

local init_routine = coroutine.create(init_plugins)

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  desc = "Fetch plugins",
  callback = function()
    coroutine.resume(init_routine)
  end
})

