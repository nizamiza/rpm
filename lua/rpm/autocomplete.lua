local M = {}

M.commands = {
  help = {
    desc = "Get help for a command",
    nargs = "?"
  },
  info = {
    desc = "Get information about a plugin",
    nargs = 1
  },
  list = {
    desc = "List all installed plugins",
    nargs = 0
  },
  install = {
    desc = "Install a plugin",
    nargs = 1
  },
  install_all = {
    desc = "Install all plugins",
    nargs = 0
  },
  update = {
    desc = "Update a plugin",
    nargs = 1
  },
  update_all = {
    desc = "Update all plugins",
    nargs = 0
  },
  delete = {
    desc = "Delete a plugin",
    nargs = 1
  },
  delete_all = {
    desc = "Delete all plugins",
    nargs = 0
  },
  clean = {
    desc = "Delete plugins that don't have a config file",
    nargs = 0
  },
  generate_helptags = {
    desc = "Generate helptags for a plugin",
    nargs = 1
  },
}

M.command_names = {}
M.name_padding = 0

for command, _ in pairs(M.commands) do
  table.insert(M.command_names, command)

  if #command > M.name_padding then
    M.name_padding = #command
  end
end

local indent = string.rep(" ", M.name_padding + 3)

function M.get_command_args_info(command)
  if command == nil then
    return {
      has_args = false,
      max_args = math.huge,
      min_args = 0
    }
  end

  local has_args = type(command.nargs) == "string" or command.nargs > 0

  local max_args = command.nargs == "?" and 1
      or (command.nargs == "+" or M.commands.nargs == "*") and math.huge
      or command.nargs

  local min_args = (command.nargs == "?" or command.nargs == "*") and 0
      or max_args

  return {
    has_args = has_args,
    max_args = max_args,
    min_args = min_args
  }
end

function M.get_command_help(name)
  local command = M.commands[name]

  if not command then
    return "Command " .. name .. " not found."
  end

  local padded_name = name .. string.rep(" ", M.name_padding - #name)

  local has_args = M.get_command_args_info(command).has_args

  return padded_name .. " - " .. command.desc .. "\n" ..
      indent .. "Required arguments: " .. command.nargs .. "\n" ..
      indent .. "Usage: `:Rpm " .. name .. (has_args and " <args>" or "") .. "`"
end

function M.narrow_options(options, arg_lead)
  local matches = {}
  local arg_lead_lower = arg_lead:lower()

  for _, option in ipairs(options) do
    if string.match(option:lower(), arg_lead_lower) then
      table.insert(matches, option)
    end
  end

  return matches
end

function M.create_autocomplete(plugin_list)
  local function autocomplete(arg_lead, cmd_line)
    local args = vim.split(cmd_line, " ")

    if #args == 1 then
      return M.command_names
    end

    local cmd = args[2]:lower()
    local command = M.commands[cmd]

    local args_info = M.get_command_args_info(command)
    local has_args = args_info.has_args
    local max_args = args_info.max_args
    local is_over_max_args = #args - 2 > max_args

    local is_cmd_passed = #args > 2

    if not has_args and is_cmd_passed or is_over_max_args then
      return {}
    end

    local is_help = cmd == "help"

    return has_args and not is_help and
        M.narrow_options(plugin_list, arg_lead) or
        M.narrow_options(M.command_names, arg_lead)
  end

  return autocomplete
end

return M
