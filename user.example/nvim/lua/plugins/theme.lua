-- Load all theme plugins so switching is instant
local slicker_dir = vim.fn.expand("~/.config/slicker")
local theme_file = slicker_dir .. "/theme/neovim.lua"
local specs = {}
local seen = {}

-- Collect plugins from all themes
local themes_dir = slicker_dir .. "/themes"
local handle = vim.uv.fs_scandir(themes_dir)
if handle then
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if typ == "directory" then
      local path = themes_dir .. "/" .. name .. "/neovim.lua"
      local ok, theme = pcall(dofile, path)
      if ok and type(theme) == "table" then
        for _, entry in ipairs(theme) do
          if type(entry) == "table" and entry[1] and entry[1]:match("/") then
            local key = entry[1]
            if not seen[key] then
              seen[key] = true
              specs[#specs + 1] = { entry[1], name = entry.name, priority = entry.priority, lazy = true }
            end
          end
        end
      end
    end
  end
end

-- Set colorscheme from current theme
local ok, theme = pcall(dofile, theme_file)
if ok and type(theme) == "table" then
  for _, entry in ipairs(theme) do
    if type(entry) == "table" and entry.opts and entry.opts.colorscheme then
      specs[#specs + 1] = {
        "LazyVim/LazyVim",
        opts = { colorscheme = entry.opts.colorscheme },
      }
      break
    end
  end
end

return specs
