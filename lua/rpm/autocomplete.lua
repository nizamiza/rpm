local commands = {
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
  }
}

local command_names = {}
local name_padding = 0

for command, _ in pairs(commands) do
  table.insert(command_names, command)

  if #command > name_padding then
    name_padding = #command
  end
end

local indent = string.rep(" ", name_padding + 3)

local function get_command_args_info(command)
  if command == nil then
    return {
      has_args = false,
      max_args = math.huge,
      min_args = 0
    }
  end

  local has_args = type(command.nargs) == "string" or command.nargs > 0

  local max_args = command.nargs == "?" and 1
    or (command.nargs == "+" or commands.nargs == "*") and math.huge
    or command.nargs

  local min_args = (command.nargs == "?" or command.nargs == "*") and 0
    or max_args

  return {
    has_args = has_args,
    max_args = max_args,
    min_args = min_args
  }
end

local function get_command_help(name)
  local command = commands[name]

  if not command then
    return "Command " .. name .. " not found."
  end

  local padded_name = name .. string.rep(" ", name_padding - #name)

  local has_args = get_command_args_info(command).has_args

  return padded_name .. " - " .. command.desc .. "\n" ..
    indent .. "Required arguments: " .. command.nargs .. "\n" ..
    indent .. "Usage: `:Rpm " .. name .. (has_args and " <args>" or "") .. "`"
end


local function narrow_options(options, arg_lead)
  local matches = {}
  local arg_lead_lower = arg_lead:lower()

  for _, option in ipairs(options) do
    if string.match(option:lower(), arg_lead_lower) then
      table.insert(matches, option)
    end
  end

  return matches
end

local function create_autocomplete(plugin_list)
  local function autocomplete(arg_lead, cmd_line)
    local args = vim.split(cmd_line, " ")

    if #args == 1 then
      return command_names
    end

    local cmd = args[2]:lower()
    local command = commands[cmd]

    local args_info = get_command_args_info(command)
    local has_args = args_info.has_args
    local max_args = args_info.max_args
    local is_over_max_args = #args - 2 > max_args

    local is_cmd_passed = #args > 2

    if not has_args and is_cmd_passed or is_over_max_args then
      return {}
    end

    local is_help = cmd == "help"

    return has_args and not is_help and
      narrow_options(plugin_list, arg_lead) or
      narrow_options(command_names, arg_lead)
  end

  return autocomplete
end

local Autocomplete = {
  create = create_autocomplete,
  commands = commands,
  command_names = command_names,
  get_command_help = get_command_help,
  get_command_args_info = get_command_args_info,
  narrow_options = narrow_options
}

return Autocomplete
