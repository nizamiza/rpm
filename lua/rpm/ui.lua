local M = {}

function M.open_float(lines, opts)
  lines = lines or {}
  opts = opts or {}

  local buf = vim.api.nvim_create_buf(false, true)
  local buf_opts = vim.tbl_extend("force", {
    buftype = "nofile",
    bufhidden = "wipe",
    buflisted = false,
    filetype = "rpm_info"
  }, opts.buf or {})

  for key, value in pairs(buf_opts) do
    vim.api.nvim_buf_set_option(buf, key, value)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, vim.tbl_extend("force", {
    title = "RPM Info",
    relative = "win",
    width = 60,
    anchor = "SW",
    row = 9999,
    col = 9999,
    height = #lines,
    border = "solid",
    style = "minimal",
  }, opts))

  local win_opts = vim.tbl_extend("force", {
    wrap = false
  }, opts.win or {})

  for key, value in pairs(win_opts) do
    vim.api.nvim_win_set_option(win, key, value)
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", {
    noremap = true,
    silent = true
  })

  vim.api.nvim_set_current_win(win)
end

return M
