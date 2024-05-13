local M = {}

function M.parse_input_answer(answer)
  if answer:lower():match("^y") then
    return true
  end

  return false
end

function M.get_plugin_version(install_path)
  return vim.fn.isdirectory(install_path) == 0 and "Not installed" or
      vim.fn.system({ "git", "-C", install_path, "describe", "--tags" }):gsub("\n", "")
end

function M.coerce_to_table(value)
  if type(value) == "table" then
    return value
  end

  return { value }
end

function M.silent_print(message, silent)
  silent = silent or false

  if not silent then
    print(message)
  end
end

function M.get_plugin_info(path)
  local paths = M.coerce_to_table(path)

  -- Consider the last path as the main dependency
  local last_path = paths[#paths]

  local name = last_path:match("([^/]+)$"):gsub("%.[a-zA-Z0-9]+", "")
  local install_path = vim.fn.stdpath("config") .. "/pack/plugins/start/" .. name

  local version = M.get_plugin_version(install_path)

  return {
    install_path = install_path,
    name = name,
    path = last_path,
    version = version
  }
end

function M.is_plugin_installed(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    local info = M.get_plugin_info(p)

    if vim.fn.isdirectory(info.install_path) == 0 then
      M.silent_print("Dependency " .. info.name .. " is not installed.", silent)
      return false
    end
  end

  return true
end

function M.generate_helptags(path, silent)
  local info = M.get_plugin_info(path)
  local doc_dir = info.install_path .. "/doc"

  if vim.fn.isdirectory(doc_dir) == 1 then
    M.silent_print("Generating help tags for " .. info.name .. "...", silent)

    vim.cmd("helptags " .. doc_dir)

    M.silent_print("Help tags for " .. info.name .. " have been generated!", silent)
  end
end

function M.install_plugin(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    if M.is_plugin_installed(p, true) then
      M.silent_print("Dependency " .. p .. " is already installed.\n", silent)
      goto continue
    end

    local url = p:match("^http") and p or "https://github.com/" .. p
    local info = M.get_plugin_info(p)

    M.silent_print("Cloning " .. url .. " to " .. info.install_path .. "...", silent)

    vim.fn.system({ "git", "clone", url, info.install_path })

    M.generate_helptags(p, silent)

    M.silent_print("Dependency " .. info.name .. " has been installed!", silent)
    ::continue::
  end
end

function M.update_plugin(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    if not M.is_plugin_installed(p) then
      M.silent_print("Dependency " .. p .. " is not installed.", silent)

      local answer = "n"

      if not silent then
        answer = vim.fn.input("Would you like to install it? (y/n): ")
      end

      if not M.parse_input_answer(answer) then
        goto continue
      end

      if not silent then
        print("\n")
      end

      M.install_plugin(p, silent)
      goto continue
    end

    local info = M.get_plugin_info(p)

    M.silent_print("Updating dependency " .. info.name .. "...", silent)

    vim.fn.system({ "git", "-C", info.install_path, "pull" })

    local new_version = M.get_plugin_version(info.install_path)

    if info.version == new_version then
      M.silent_print("Dependency " .. info.name .. " is already up to date.", silent)
    else
      M.silent_print("Dependency " .. info.name .. " has been updated to " .. new_version .. "!", silent)
    end

    ::continue::
  end
end

function M.delete_plugin(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    local info = M.get_plugin_info(p)

    if vim.fn.isdirectory(info.install_path) == 0 then
      M.silent_print("Dependency " .. info.name .. " is not installed.\n", silent)
      goto continue
    end

    if not silent then
      local answer = vim.fn.input("Are you sure you want to delete " .. info.name .. "? (y/n): ")

      if not M.parse_input_answer(answer) then
        goto continue
      end

      print("\n")
    end

    M.silent_print("Deleting " .. info.name .. "...", silent)

    vim.fn.system({ "rm", "-rf", info.install_path })

    M.silent_print("Dependency " .. info.name .. " has been deleted.", silent)
    ::continue::
  end
end

return M
