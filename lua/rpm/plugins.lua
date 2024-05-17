---@class PluginDefinition
---@field module_name string
---@field path string|table
---@field initialized boolean
---@field init_fn function

---@alias PluginMap table<string, PluginDefinition>

local Constants = require("rpm.constants")
local UI = require("rpm.ui")

local M = {
  count = 0,
  loaded = false,
  _ = {
    ---@type PluginMap
    cached_plugins = {}
  }
}

---@param dir string
---@return string[]
function M.get_config_paths(dir)
  local dir_path = dir:gsub("^/", ""):gsub("/$", "")

  return vim.fn.globpath(
    vim.fn.stdpath("config") .. "/lua/" .. dir_path, "*.lua",
    false,
    true
  )
end

---@class LoadOptions
---@field force? boolean
---@field on_complete? fun(plugins: PluginMap): nil

---@class LoadPlugins
---@field wait fun(): PluginMap

---@param options? LoadOptions
---@return LoadPlugins
function M.load(options)
  local opts = options or {}

  local config_paths = vim.tbl_extend("force",
    M.get_config_paths("plugins"),
    M.get_config_paths("custom/plugins")
  )

  if not opts.force and M.loaded then
    if M.count == #config_paths and #M._.cached_plugins == #config_paths then
      return M._.cached_plugins
    end
  end

  M.count = #config_paths
  M.loaded = false

  ---@type PluginMap
  local plugins = {}

  local current_count = 0

  for _, path in ipairs(config_paths) do
    vim.schedule(function()
      local module_name = path:match("([^/]+)$"):gsub("%.lua$", "")

      local plugin_definition = require("plugins." .. module_name)

      local plugin_path = plugin_definition[1]
      local init_fn = plugin_definition[2]

      if not plugin_path then
        UI.notify("Plugin " .. module_name .. " does not have a GitHub path nor a custom URL.", {
          level = vim.log.levels.WARN
        })
        return
      end

      plugins[module_name] = {
        module_name = module_name,
        path = plugin_path,
        initialized = false,
        init_fn = init_fn or function() end
      }

      current_count = current_count + 1

      if current_count == M.count then
        M.loaded = true
        M._.cached_plugins = plugins

        if opts.on_complete then
          opts.on_complete(plugins)
        end
      end
    end)
  end

  return {
    wait = function()
      local loaded = vim.wait(Constants.INIT_INTERVAL, function()
        return M.loaded
      end, Constants.INIT_INTERVAL)

      return loaded and plugins or {}
    end
  }
end

return M
