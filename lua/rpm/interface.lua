local core = require("rpm.core")
local plugin_list = require("rpm.plugin_list")
local Autocomplete = require("rpm.autocomplete")

local plugin_names = {}

for name in pairs(plugin_list) do
  table.insert(plugin_names, name)
end

local function get_plugin(plugin_name)
  local plugin = plugin_list[plugin_name] 

  if not plugin then
    print("Plugin " .. plugin_name .. " not found.\n")
    return nil
  end

  return plugin
end

local function use_plugin_list_op_with_routines(fn, args)
  for name, plugin in pairs(plugin_list) do
    local routine = coroutine.create(function()
      fn(name, plugin, args)
    end)

    coroutine.resume(routine)
  end
end

-- RPM - Rudimentary Plugin Manager
local Rpm = {
  commands = Autocomplete.commands,
  command_names = Autocomplete.command_names,
  get_command_args_info = Autocomplete.get_command_args_info,
  autocomplete = Autocomplete.create(plugin_names),
  get = get_plugin
}

Rpm.help = function(command_name)
  if command_name then
    print(Autocomplete.get_command_help(command_name))
    return
  end

  print("Available commands:\n")

  for _, command in ipairs(Autocomplete.command_names) do
    print("\n" .. Autocomplete.get_command_help(command))
  end
end

Rpm.info = function(plugin_name)
  local plugin = get_plugin(plugin_name)

  if not plugin then
    return
  end

  local info = core.get_plugin_info(plugin.path)

  print("Name: " .. info.name)
  print("Version: " .. info.version)
  print("Path: " .. info.path)
  print("Installation Path: " .. info.install_path)
end

Rpm.list = function()
  use_plugin_list_op_with_routines(function(name, plugin)
    local info = core.get_plugin_info(plugin.path)
    print(info.name .. " (" .. info.version .. ")")
  end)
end

Rpm.install = function(plugin_name)
  local plugin = get_plugin(plugin_name)

  if not plugin then
    return
  end

  core.install_plugin(plugin.path)
end

Rpm.update = function(plugin_name)
  local plugin = get_plugin(plugin_name)

  if not plugin then
    return
  end

  core.update_plugin(plugin.path)
end

Rpm.delete = function(plugin_name, silent)
  silent = silent or false
  local plugin = get_plugin(plugin_name)
  
  if not plugin then
    return
  end

  core.delete_plugin(plugin.path, silent)
end

Rpm.install_all = function()
  print("Installing all plugins...\n")

  use_plugin_list_op_with_routines(function(name)
    Rpm.install(name)
  end)

  print("\nAll plugins have been installed.")
end

Rpm.update_all = function()
  print("Updating all plugins...\n")

  use_plugin_list_op_with_routines(function(name)
    Rpm.update(name)
  end)

  print("\nAll plugins have been updated.")
end

Rpm.delete_all = function()
  local answer = vim.fn.input("Are you sure you want to delete all plugins? (y/n): ")

  if not core.parse_input_answer(answer) then
    return
  end

  print("\n")

  use_plugin_list_op_with_routines(function(name)
    Rpm.delete(name, true)
  end)

  print("All plugins have been deleted.")
end

Rpm.clean = function()
  local installed_plugins = vim.fn.globpath(
    vim.fn.stdpath("config") .. "/pack/plugins/start",
    "*",
    true,
    true
  )

  local all_plugin_paths = {}

  for _, plugin in pairs(plugin_list) do
    local paths = type(plugin.path) == "table" and plugin.path or { plugin.path }
    
    for _, path in ipairs(paths) do
      local info = core.get_plugin_info(path)
      table.insert(all_plugin_paths, info.name)
    end
  end

  local delete_count = 0
  for _, installed_plugin in ipairs(installed_plugins) do
    local name = installed_plugin:match("([^/]+)$")

    if not vim.tbl_contains(all_plugin_paths, name) then
      print("Deleting " .. name .. "...")
      core.delete_plugin(name, true)
      delete_count = delete_count + 1
    end
  end

  print("Deleted " .. delete_count .. " plugins.\n")
end

return Rpm
