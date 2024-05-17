local M = {}

---@class NotifyOptions
---@field level? integer

---@param message string
---@param options? NotifyOptions
---@return nil
function M.notify(message, options)
  local opts = options or {}
  vim.notify(message, opts.level or vim.log.levels.INFO)
end

---@class PromptYesNoOptions
---@field default? boolean
---@field on_yes? fun(): nil
---@field on_no? fun(): nil

---@param message string
---@param options? PromptYesNoOptions
---@return boolean
function M.prompt_yesno(message, options)
  local opts = options or {}

  local answer_str = opts.default and " [Y/n] " or " [y/N] "
  local answer = vim.fn.input(message .. answer_str)

  local is_yes = answer:lower():match("^y")

  if is_yes then
    if opts.on_yes then
      opts.on_yes()
    end
  elseif opts.on_no then
    opts.on_no()
  end

  return is_yes
end

---@param lines string[]
---@param win_opts? vim.api.keyset.win_config
---@param buf_opts? table
---@return nil
function M.open_float(lines, win_opts, buf_opts)
  lines = lines or {}
  local opts = win_opts or {}

  local buf = vim.api.nvim_create_buf(false, true)
  local bufopts = vim.tbl_extend("force", {
    buftype = "nofile",
    bufhidden = "wipe",
    buflisted = false,
    filetype = "rpm_info"
  }, buf_opts or {})

  for key, value in pairs(bufopts) do
    vim.api.nvim_set_option_value(key, value, {
      buf = buf
    })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local g_height = vim.api.nvim_list_uis()[1].height
  local g_width = vim.api.nvim_list_uis()[1].width

  local width = opts.width or 80
  local height = opts.height or #lines

  local win = vim.api.nvim_open_win(buf, true, vim.tbl_extend("force", {
    title = "RPM Info",
    relative = "editor",
    width = width,
    height = height,
    row = (g_height - height) / 2,
    col = (g_width - width) / 2,
    border = "solid",
    style = "minimal",
  }, opts))

  vim.api.nvim_set_option_value("modifiable", false, {
    buf = buf
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", {
    noremap = true,
    silent = true
  })

  vim.api.nvim_set_current_win(win)
end

return M
