local function get_plugin_version(install_path)
  return vim.fn.isdirectory(install_path) == 0 and "Not installed" or
    vim.fn.system({ "git", "-C", install_path, "describe", "--tags" }):gsub("\n", "")
end

local function coerce_to_table(value)
  if type(value) == "table" then
    return value
  end

  return { value }
end

local silent_print = function(message, silent)
  silent = silent or false

  if not silent then
    print(message)
  end
end

local function get_plugin_info(path)
  local paths = coerce_to_table(path)

  -- Consider the last path as the main dependency
  local last_path = paths[#paths]

  local name = last_path:match("([^/]+)$"):gsub("%.[a-zA-Z0-9]+", "")
  local install_path = vim.fn.stdpath("config") .. "/pack/plugins/start/" .. name

  local version = get_plugin_version(install_path)

  return {
    install_path = install_path,
    name = name,
    path = last_path,
    version = version
  }
end

local function is_plugin_installed(path, silent)
  local paths = coerce_to_table(path) 

  for _, p in ipairs(paths) do
    local info = get_plugin_info(p)

    if vim.fn.isdirectory(info.install_path) == 0 then
      silent_print("Dependency " .. info.name .. " is not installed.", silent)
      return false
    end
  end

  return true
end

local function install_plugin(path, silent)
  local paths = coerce_to_table(path)

  for _, p in ipairs(paths) do
    if is_plugin_installed(p, true) then
      silent_print("Dependency " .. p .. " is already installed.\n", silent)
      goto continue
    end

    local url = p:match("^http") and p or "https://github.com/" .. p
    local info = get_plugin_info(p)

    silent_print("Cloning " .. url .. " to " .. info.install_path .. "...", silent)

    vim.fn.system({ "git", "clone", url, info.install_path })

    silent_print("Dependency " .. info.name .. " has been installed!", silent)
    ::continue::
  end
end 

local function update_plugin(path, silent)
  local paths = coerce_to_table(path)

  for _, p in ipairs(paths) do
    if not is_plugin_installed(p) then
      silent_print("Dependency " .. p .. " is not installed.", silent)

      local answer = "n"

      if not silent then
        answer = vim.fn.input("Would you like to install it? (y/n): ")
      end

      if answer ~= "y" then
        goto continue
      end

      if not silent then
        print("\n")
      end

      install_plugin(p, silent)
      goto continue
    end

    local info = get_plugin_info(p)

    silent_print("Updating dependency " .. info.name .. "...", silent)

    vim.fn.system({ "git", "-C", info.install_path, "pull" })

    local new_version = get_plugin_version(info.install_path)

    if info.version == new_version then
      silent_print("Dependency " .. info.name .. " is already up to date.", silent)
    else
      silent_print("Dependency " .. info.name .. " has been updated to " .. new_version .. "!", silent)
    end

    ::continue::
  end
end

local function delete_plugin(path, silent)
  local paths = coerce_to_table(path)

  for _, p in ipairs(paths) do
    local info = get_plugin_info(p)

    if vim.fn.isdirectory(info.install_path) == 0 then
      silent_print("Dependency " .. info.name .. " is not installed.\n", silent)
      goto continue
    end

    if not silent then
      local answer = vim.fn.input("Are you sure you want to delete " .. info.name .. "? (y/n): ")

      if answer ~= "y" then
        goto continue
      end

      print("\n")
    end

    silent_print("Deleting " .. info.name .. "...", silent)

    vim.fn.system({ "rm", "-rf", info.install_path })

    silent_print("Dependency " .. info.name .. " has been deleted.", silent)
    ::continue::
  end
end

return {
  delete_plugin = delete_plugin,
  get_plugin_info = get_plugin_info,
  install_plugin = install_plugin, 
  is_plugin_installed = is_plugin_installed,
  update_plugin = update_plugin
}
