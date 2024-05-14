local Interface = require("rpm.interface")

vim.api.nvim_create_user_command(
  "Rpm",
  function(cmd)
    local command = cmd.fargs[1]

    if not command then
      print("No command provided.")
      return
    end

    local rpm_command = Interface.commands[command]

    if not rpm_command then
      print("Invalid command. Run `:Rpm help` for a list of commands.")
      return
    end

    local args_info = Interface.get_command_args_info(rpm_command)
    local min_args = args_info.min_args
    local max_args = args_info.max_args

    if #cmd.fargs - 1 > max_args or #cmd.fargs - 1 < min_args then
      print("Invalid number of arguments.")
      Interface.help(command)
      return
    end

    local args = {}
    for i = 2, #cmd.fargs do
      table.insert(args, cmd.fargs[i])
    end

    Interface[command](unpack(args))
  end,
  {
    nargs = "+",
    desc = "Run an RPM command",
    complete = Interface.autocomplete
  }
)
