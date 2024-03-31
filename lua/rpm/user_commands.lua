local Rpm = require("rpm.interface")

vim.api.nvim_create_user_command(
  "Rpm",
  function(cmd)
    -- we get 2 arguments, the first one is the command and the second one is the
    -- plugin name.
    
    local command = cmd.args[1]
    local plugin_name = cmd.args[2]
    
    if not command then
      print("No command provided.")
      return
    end

    command = command:lower()

    if not vim.tbl_contains(Rpm.command_list, command) then
      print("Invalid command. Available commands are:")
      print(table.concat(Rpm.command_list, ", "))
      return
    end

    if not plugin_name then
      print("No plugin name provided.")
      return
    end

    plugin_name = plugin_name:lower()

    if command:match("all$") then
      Rpm[command]()
    else
      Rpm[command](plugin_name)
    end
  end,
  {
    nargs = "+",
    desc = "Run an RPM command",
    complete = Rpm.autocomplete
  }
)
