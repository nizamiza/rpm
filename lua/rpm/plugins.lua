local M = {}

local configs = vim.fn.globpath(
  vim.fn.stdpath("config") .. "/lua/plugins", "*.lua",
  false,
  true
)

M._ = {
  count = #configs,
  loaded = false
}

local current_count = 0

for _, file in ipairs(configs) do
  vim.schedule(function()
    local module_name = file:match("([^/]+)$"):gsub("%.lua$", "")

    local plugin = require("plugins." .. module_name)

    M[module_name] = {
      module_name = module_name,
      path = plugin[1],
      initialized = false,
      init_fn = plugin[2] or function() end
    }

    if current_count == M._.count then
      M._.loaded = true
    end
  end)
end

return M
