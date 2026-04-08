-- Slicker theme integration
-- Reads theme spec from ~/.config/slicker/theme/neovim.lua
local theme_path = os.getenv("HOME") .. "/.config/slicker/theme/neovim.lua"
local ok, theme = pcall(dofile, theme_path)
if not ok or type(theme) ~= "table" then
  return {}
end

return {
  theme.plugin,
  { "LazyVim/LazyVim", opts = { colorscheme = theme.colorscheme } },
}
