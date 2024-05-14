local M = {}

local Core = require("rpm.core")
local Plugins = require("rpm.plugins")
local Autocomplete = require("rpm.autocomplete")
local UI = require("rpm.ui")

M.plugin_names = {}
M.commands = Autocomplete.commands
M.command_names = Autocomplete.command_names
M.get_command_args_info = Autocomplete.get_command_args_info
M.autocomplete = Autocomplete.create(M.plugin_names)

M._ = {
  after_init = function(plugin_list)
    for name in pairs(plugin_list) do
      if (name == "_") then
        goto continue
      end

      table.insert(M.plugin_names, name)
      ::continue::
    end

    table.sort(M.plugin_names)
  end
}

function M.get(plugin_name)
  local plugin = Plugins[plugin_name]

  if not plugin then
    print("Plugin " .. plugin_name .. " not found.\n")
    return nil
  end

  return plugin
end

function M.schedule_plugin_list_op(fn, opts)
  opts = opts or {}

  local args = opts.args
  local on_complete = opts.on_complete

  vim.schedule(function()
    local count = 0

    for name, plugin in pairs(Plugins) do
      vim.schedule(function()
        fn(name, plugin, args)
        count = count + 1

        if count == Plugins._.count and on_complete then
          vim.schedule(on_complete)
        end
      end)
    end
  end)
end

function M.help(command_name)
  if command_name then
    print(Autocomplete.get_command_help(command_name))
    return
  end

  print("Available commands:\n")

  for _, command in ipairs(Autocomplete.command_names) do
    print("\n" .. Autocomplete.get_command_help(command))
  end
end

function M.generate_helptags(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  Core.generate_helptags(plugin.path)
end

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

function M.list()
  local lines = {}

  for _, name in ipairs(M.plugin_names) do
    local plugin = M.get(name)

    if not plugin then
      goto continue
    end

    local info = Core.get_plugin_info(plugin.path)

    table.insert(lines, info.name .. " (" .. info.version .. ")")
    ::continue::
  end

  UI.open_float(lines, {
    title = "Installed Plugins",
  })
end

function M.install(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  Core.install_plugin(plugin.path)
end

function M.update(plugin_name)
  local plugin = M.get(plugin_name)

  if not plugin then
    return
  end

  Core.update_plugin(plugin.path)
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

    if not Core.parse_input_answer(answer) then
      return
    end
  end

  Core.delete_plugin(plugin.path, silent)
end

function M.install_all()
  vim.notify("Installing all plugins...")

  M.schedule_plugin_list_op(
    function(name)
      M.install(name)
    end,
    {
      on_complete = function()
        vim.notify("All plugins have been installed.")
      end
    }
  )
end

function M.update_all()
  vim.notify("Updating all plugins...")

  M.schedule_plugin_list_op(
    function(name)
      M.update(name)
    end,
    {
      on_complete = function()
        vim.notify("All plugins have been updated.")
      end
    }
  )
end

function M.delete_all()
  local answer = vim.fn.input("Are you sure you want to delete all plugins? (y/n): ")

  if not Core.parse_input_answer(answer) then
    return
  end

  M.schedule_plugin_list_op(
    function(name)
      if name == "rpm" then
        return
      end

      M.delete(name, true)
    end,
    {
      on_complete = function()
        vim.notify("All plugins (except for RPM) have been deleted.")
      end
    }
  )
end

function M.clean()
  local installed_plugins = vim.fn.globpath(
    vim.fn.stdpath("config") .. "/pack/plugins/start",
    "*",
    true,
    true
  )

  local all_plugin_paths = {}

  for _, plugin in pairs(Plugins) do
    local paths = type(plugin.path) == "table" and plugin.path or { plugin.path }

    for _, path in ipairs(paths) do
      local info = Core.get_plugin_info(path)
      table.insert(all_plugin_paths, info.name)
    end
  end

  local delete_count = 0
  for _, installed_plugin in ipairs(installed_plugins) do
    local name = installed_plugin:match("([^/]+)$")

    if not vim.tbl_contains(all_plugin_paths, name) then
      vim.notify("Deleting " .. name .. "...")
      Core.delete_plugin(name, true)
      delete_count = delete_count + 1
    end
  end

  vim.notify("Deleted " .. delete_count .. " plugins.")
end

function M.setup(opts)
  opts = opts or {}

  if opts.after_init and type(opts.after_init) == "function" then
    M.after_init = opts.after_init
  end
end

return M
