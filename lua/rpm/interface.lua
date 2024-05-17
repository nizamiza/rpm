local M = {}

local Core = require("rpm.core")
local Plugins = require("rpm.plugins")
local Autocomplete = require("rpm.autocomplete")
local Constants = require("rpm.constants")
local UI = require("rpm.ui")

M.commands = Autocomplete.commands
M.command_names = Autocomplete.command_names
M.get_command_args_info = Autocomplete.get_command_args_info
M.autocomplete = Autocomplete.get_completion

---@param plugin_name string
---@return PluginDefinition|nil
function M.get(plugin_name)
  local plugin = Plugins.load():wait()[plugin_name]

  if not plugin then
    print("Plugin " .. plugin_name .. " not found.\n")
    return nil
  end

  return plugin
end

---@class SchedulePluginListOpOptions
---@field args? table
---@field on_complete? fun()

---@param fn fun(plugin_name: string, plugin: PluginDefinition, args?: table)
---@param options? SchedulePluginListOpOptions
---@return nil
function M.perform_plugin_list_op(fn, options)
  local opts = options or {}

  local args = opts.args
  local on_complete = opts.on_complete

  for name, plugin in pairs(Plugins.load():wait()) do
    fn(name, plugin, unpack(args or {}))
  end

  if on_complete then
    vim.schedule(on_complete)
  end
end

---@param command_name? string
---@return nil
function M.help(command_name)
  ---@type string[]
  local lines = {}

  if command_name then
    lines = Autocomplete.get_command_help(command_name)
  else
    lines = vim.iter(Autocomplete.command_names)
        :map(function(command)
          return Autocomplete.get_command_help(command)
        end)
        :flatten()
        :totable()
  end

  UI.open_float(lines, {
    title = command_name and ("Rpm `" .. command_name .. "`") or "RPM Help",
  })
end

---@param plugin_name string
---@return nil
function M.generate_helptags(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  Core.generate_helptags(plugin.path)
end

---@param plugin_name string
---@return nil
function M.info(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  local info = Core.get_plugin_info(plugin.path)

  UI.open_float({
    "Name: " .. info.name,
    "Version: " .. info.version,
    "Path: " .. info.path,
    "Installation Path: " .. info.install_path
  }, {
    title = info.name,
  })
end

---@return nil
function M.list()
  local lines = {}

  M.perform_plugin_list_op(
    function(_, plugin)
      local info = Core.get_plugin_info(plugin.path)
      local version = info.version ~= "" and " (" .. info.version .. ")" or ""

      table.insert(lines, info.name .. version)
    end,
    {
      on_complete = function()
        UI.open_float(lines, {
          title = "Installed Plugins",
        })
      end
    }
  )
end

---@param plugin_name string
---@return nil
function M.install(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  Core.install_plugin(plugin.path)
end

---@param plugin_name string
---@return nil
function M.update(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  Core.update_plugin(plugin.path)
end

---@param plugin_name string
---@param silent? boolean
---@return nil
function M.delete(plugin_name, silent)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  local message = plugin_name == Constants.PLUGIN_NAME and
      "Are you sure you want to delete RPM? This is your plugin manager :D" or
      "Are you sure you want to delete " .. plugin_name .. "?"

  local proceed = silent or UI.prompt_yesno(message)

  if not proceed then
    return
  end

  Core.delete_plugin(plugin.path, silent)
end

---@return nil
function M.install_all()
  UI.notify("Installing all plugins...")

  M.perform_plugin_list_op(M.install, {
    on_complete = function()
      UI.notify("All plugins have been installed.")
    end
  })
end

function M.update_all()
  UI.notify("Updating all plugins...")

  M.perform_plugin_list_op(M.update, {
    args = { silent = true },
    on_complete = function()
      UI.notify("All plugins have been updated.")
    end
  })
end

---@return nil
function M.delete_all()
  local proceed = UI.prompt_yesno("Are you sure you want to delete all plugins?")

  if not proceed then
    return
  end

  for name in pairs(Plugins.load():wait()) do
    if name ~= Constants.PLUGIN_NAME then
      UI.notify("Deleting " .. name .. "...")
      M.delete(name, true)
    end
  end

  UI.notify("All plugins (except for RPM) have been deleted.")
end

---@return nil
function M.clean()
  local installed_plugins = vim.fn.globpath(
    vim.fn.stdpath("config") .. "/pack/plugins/start",
    "*",
    true,
    true
  )

  local all_plugin_paths = {}

  for _, plugin in pairs(Plugins.load():wait()) do
    local paths = Core.coerce_to_table(plugin.path)

    for _, path in ipairs(paths) do
      local info = Core.get_plugin_info(path)
      table.insert(all_plugin_paths, info.name)
    end
  end

  local delete_count = 0
  for _, installed_plugin in ipairs(installed_plugins) do
    local name = installed_plugin:match("([^/]+)$")

    if not vim.tbl_contains(all_plugin_paths, name) then
      UI.notify("Deleting " .. name .. "...")
      Core.delete_plugin(name, true)
      delete_count = delete_count + 1
    end
  end

  UI.notify("Deleted " .. delete_count .. " plugins.")
end

---@class SetupOptions
---@field after_init? fun()

---@param opts? SetupOptions
---@return nil
function M.setup(opts)
  local options = opts or {}
  local after_init = options.after_init

  if after_init and type(after_init) == "function" then
    M.after_init = after_init
  end
end

return M
