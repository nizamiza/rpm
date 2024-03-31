local command_list = {
  "info",
  "list",
  "install",
  "install_all",
  "update",
  "update_all",
  "delete",
  "delete_all",
  "clean"
}

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

-- We have 2 arguments for completion. First we need to complete against
-- `command_list` and then against `plugin_names`.
--
-- E.g. Rpm <tab> -> complete from command_list...
-- E.g. Rpm info <tab> -> complete from plugin_names...
--
local function create_autocomplete(plugin_list)
  local function autocomplete(arg_lead, cmd_line)
    if #arg_lead == 0 then
      return narrow_options(command_list, arg_lead)
    end

    local cmd = cmd_line:match("Rpm%s+(%w+)%s+")

    if not cmd then
      return
    end

    cmd = cmd:lower()

    if cmd:match("all$") then
      return
    end

    return narrow_options(plugin_names, arg_lead)
  end

  return autocomplete
end

local Autocomplete = {
  create = create_autocomplete,
  command_list = command_list
}

return Autocomplete
