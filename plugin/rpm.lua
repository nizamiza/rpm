if vim.g.loaded_rpm == 1 then
  return
end

vim.g.loaded_rpm = 1

require("rpm.user_commands")

vim.cmd [[
  if exists('*tagfiles')
    if empty(tagfiles())
      set tagfiles+=doc/rpm.txt
    endif
  endif
]]
