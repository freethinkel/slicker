-- ─── Slicker Neovim ──────────────────────────────────────────────────
-- Base layer — managed by slicker.
-- User plugins: user/nvim/lua/user/plugins/*.lua

-- Add user lua path to runtimepath
local user_nvim = os.getenv("HOME") .. "/.config/slicker/user/nvim"
if vim.fn.isdirectory(user_nvim) == 1 then
  vim.opt.rtp:prepend(user_nvim)
end

require("config.options")
require("config.lazy")
