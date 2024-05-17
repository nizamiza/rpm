---@alias PluginPath string|table

local UI = require("rpm.ui")

local M = {}

---@param install_path string
---@return string
function M.get_plugin_version(install_path)
  if vim.fn.isdirectory(install_path) == 0 then
    return "Not installed"
  end

  local tag_info = vim.system({ "git", "-C", install_path, "describe", "--tags" }):wait()

  if tag_info.code ~= 0 or not tag_info.stdout then
    return ""
  end

  local version = tag_info.stdout:gsub("\n", "")
  return version
end

---@param value any
---@return table
function M.coerce_to_table(value)
  if not value then
    return {}
  end

  if type(value) == "table" then
    return value
  end

  return { value }
end

---@param message? string
---@param silent? boolean
---@param options? NotifyOptions
---@return nil
function M.silent_print(message, silent, options)
  local opts = options or {}

  if not silent then
    UI.notify(message or "", opts)
  end
end

---@class PluginInfo
---@field install_path string
---@field name string
---@field path string
---@field version string

---@param path PluginPath
---@return PluginInfo
function M.get_plugin_info(path)
  local paths = M.coerce_to_table(path)

  if #paths == 0 then
    return {
      install_path = "Unknown",
      name = vim.inspect(path) or "Unknown",
      path = "Unknown",
      version = "Unknown"
    }
  end

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

---@param path PluginPath
---@param silent? boolean
---@return boolean
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

---@param path PluginPath
---@param silent? boolean
---@return nil
function M.generate_helptags(path, silent)
  local info = M.get_plugin_info(path)
  local doc_dir = info.install_path .. "/doc"

  if vim.fn.isdirectory(doc_dir) == 1 then
    M.silent_print("Generating help tags for " .. info.name .. "...", silent)

    vim.cmd("helptags " .. doc_dir)

    M.silent_print("Help tags for " .. info.name .. " have been generated!", silent)
  end
end

---@param path PluginPath
---@param silent? boolean
---@return nil
function M.install_plugin(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    if M.is_plugin_installed(p, true) then
      M.silent_print("Dependency " .. p .. " is already installed.", silent)
      goto continue
    end

    local url = p:match("^http") and p or "https://github.com/" .. p
    local info = M.get_plugin_info(p)

    M.silent_print("Cloning " .. url .. " to " .. info.install_path .. "...", silent)

    local clone_result = vim.system({
      "git",
      "clone",
      "--filter=blob:none",
      url,
      info.install_path,
    }):wait()

    if clone_result.code ~= 0 then
      M.silent_print("Failed to clone " .. url .. " to " .. info.install_path .. ".", silent, {
        level = vim.log.levels.ERROR
      })
      M.silent_print(clone_result.stderr, silent, {
        level = vim.log.levels.ERROR
      })
      goto continue
    end

    M.generate_helptags(p, silent)

    M.silent_print("Dependency " .. info.name .. " has been installed!", silent)
    ::continue::
  end
end

---@param path PluginPath
---@param silent? boolean
---@return nil
function M.update_plugin(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    if not M.is_plugin_installed(p) then
      M.silent_print("Dependency " .. p .. " is not installed.", silent)

      local proceed_with_install = false

      if not silent then
        proceed_with_install = UI.prompt_yesno("Would you like to install it?")
      end

      if not proceed_with_install then
        goto continue
      end

      M.install_plugin(p, silent)
      goto continue
    end

    local info = M.get_plugin_info(p)

    M.silent_print("Updating dependency " .. info.name .. "...", silent)

    local pull_result = vim.system({ "git", "-C", info.install_path, "pull" }):wait()

    if pull_result.code ~= 0 then
      M.silent_print("Failed to update " .. info.name .. ".", silent, {
        level = vim.log.levels.ERROR
      })
      M.silent_print(pull_result.stderr, silent, {
        level = vim.log.levels.ERROR
      })
      goto continue
    end

    local new_version = M.get_plugin_version(info.install_path)

    if info.version == new_version then
      M.silent_print("Dependency " .. info.name .. " is already up to date.", silent)
    else
      M.silent_print("Dependency " .. info.name .. " has been updated to " .. new_version .. "!", silent)
    end

    ::continue::
  end
end

---@param path PluginPath
---@param silent? boolean
---@return nil
function M.delete_plugin(path, silent)
  local paths = M.coerce_to_table(path)

  for _, p in ipairs(paths) do
    local info = M.get_plugin_info(p)

    if vim.fn.isdirectory(info.install_path) == 0 then
      M.silent_print("Dependency " .. info.name .. " is not installed.", silent, {
        level = vim.log.levels.WARN
      })
      goto continue
    end

    M.silent_print("Deleting " .. info.name .. "...", silent)

    local rm_result = vim.system({ "rm", "-rf", info.install_path }):wait()

    if rm_result.code ~= 0 then
      M.silent_print("Failed to delete " .. info.name .. ".", silent, {
        level = vim.log.levels.ERROR
      })
      goto continue
    end

    M.silent_print("Dependency " .. info.name .. " has been deleted.", silent)
    ::continue::
  end
end

return M
