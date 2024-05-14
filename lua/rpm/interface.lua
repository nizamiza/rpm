local M = {}

local core = require("rpm.core")
local plugin_list = require("rpm.plugin_list")
local autocomplete = require("rpm.autocomplete")

M.plugin_names = {}
M.commands = autocomplete.commands
M.command_names = autocomplete.command_names
M.get_command_args_info = autocomplete.get_command_args_info
M.autocomplete = autocomplete.create(M.plugin_names)

for name in pairs(plugin_list) do
  table.insert(M.plugin_names, name)
end

function M.get(plugin_name)
  local plugin = plugin_list[plugin_name]

  if not plugin then
    print("Plugin " .. plugin_name .. " not found.\n")
    return nil
  end

  return plugin
end

function M.use_plugin_list_op_with_routines(fn, args)
  for name, plugin in pairs(plugin_list) do
    local routine = coroutine.create(function()
      fn(name, plugin, args)
    end)

    coroutine.resume(routine)
  end
end

function M.help(command_name)
  if command_name then
    print(autocomplete.get_command_help(command_name))
    return
  end

  print("Available commands:\n")

  for _, command in ipairs(autocomplete.command_names) do
    print("\n" .. autocomplete.get_command_help(command))
  end
end

function M.generate_helptags(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  core.generate_helptags(plugin.path)
end

function M.info(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  local info = core.get_plugin_info(plugin.path)

  print("Name: " .. info.name)
  print("Version: " .. info.version)
  print("Path: " .. info.path)
  print("Installation Path: " .. info.install_path)
end

function M.list()
  M.use_plugin_list_op_with_routines(function(_, plugin)
    local info = core.get_plugin_info(plugin.path)
    print(info.name .. " (" .. info.version .. ")")
  end)
end

function M.install(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  core.install_plugin(plugin.path)
end

function M.update(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  core.update_plugin(plugin.path)
end

function M.delete(plugin_name, silent)
  silent = silent or false
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  local is_rpm = plugin_name == "rpm"

  if is_rpm then
    silent = true

    local answer = vim.fn.input(
      "Are you sure you want to delete RPM? This is your plugin manager :D (y/n): "
    )

    if not core.parse_input_answer(answer) then
      return
    end
  end

  core.delete_plugin(plugin.path, silent)
end

function M.install_all()
  print("Installing all plugins...\n")

  M.use_plugin_list_op_with_routines(function(name)
    M.install(name)
  end)

  print("\nAll plugins have been installed.")
end

function M.update_all()
  print("Updating all plugins...\n")

  M.use_plugin_list_op_with_routines(function(name)
    M.update(name)
  end)

  print("\nAll plugins have been updated.")
end

function M.delete_all()
  local answer = vim.fn.input("Are you sure you want to delete all plugins? (y/n): ")

  if not core.parse_input_answer(answer) then
    return
  end

  print("\n")

  M.use_plugin_list_op_with_routines(function(name)
    if name == "rpm" then
      return
    end

    M.delete(name, true)
  end)

  print("All plugins (except for RPM) have been deleted.")
end

function M.clean()
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

function M.setup(opts)
  opts = opts or {}

  if opts.after_init and type(opts.after_init) == "function" then
    M.after_init = opts.after_init
  end
end

return M
