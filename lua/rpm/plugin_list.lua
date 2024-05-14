local M = {}

local configs = vim.fn.globpath(
  vim.fn.stdpath("config") .. "/lua/plugins", "*.lua",
  false,
  true
)

for _, file in ipairs(configs) do
  local routine = coroutine.create(function()
    local module_name = file:match("([^/]+)$"):gsub("%.lua$", "")

    local plugin = require("plugins." .. module_name)

    M[module_name] = {
      path = plugin[1],
      init_fn = plugin[2] or function() end
    }
  end)

  coroutine.resume(routine)
end

return M
