if vim.g.loaded_rpm == 1 then
  return
end

vim.g.loaded_rpm = 1

require("rpm.commands")
