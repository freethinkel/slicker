-- ─── Slicker Neovim ──────────────────────────────────────────────────
-- Base layer — managed by slicker.
-- User plugins: ~/.slicker-user/nvim/lua/user/plugins/*.lua

-- Add user lua path to runtimepath
local user_nvim = os.getenv("HOME") .. "/.slicker-user/nvim"
if vim.fn.isdirectory(user_nvim) == 1 then
  vim.opt.rtp:prepend(user_nvim)
end

require("config.options")
require("config.lazy")
