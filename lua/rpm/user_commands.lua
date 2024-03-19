local Rpm = require("rpm.interface")

vim.api.nvim_create_user_command(
  Rpm.cmd_name("Info"),
  Rpm.get_info,
  {
    nargs = 1,
    desc = "Get info about a plugin",
    complete = Rpm.autocomplete
  }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("List"),
  Rpm.list,
  { nargs = 0, desc = "List all plugins" }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("Install"),
  Rpm.install,
  {
    nargs = 1,
    desc = "Install a plugin",
    complete = Rpm.autocomplete
  }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("InstallAll"),
  Rpm.install_all,
  { nargs = 0, desc = "Install all plugins" }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("Update"),
  Rpm.update,
  {
    nargs = 1,
    desc = "Update a plugin",
    complete = Rpm.autocomplete
  }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("UpdateAll"),
  Rpm.update_all,
  { nargs = 0, desc = "Update all plugins" }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("Delete"),
  Rpm.delete,
  {
    nargs = 1,
    desc = "Delete a plugin",
    complete = Rpm.autocomplete
  }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("DeleteAll"),
  Rpm.delete_all,
  { nargs = 0, desc = "Delete all plugins" }
)

vim.api.nvim_create_user_command(
  Rpm.cmd_name("Clean"),
  Rpm.clean,
  { nargs = 0, desc = "Delete all non-configured plugins" }
)
