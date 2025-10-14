-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Get the global vim object
local map = vim.keymap.set

-- Map F5 to run ./run.sh in Alacritty and keep it open
map("n", "<C-b>", function()
  vim.fn.system('alacritty -e bash -c "./run.sh; exec bash" &')
end, { desc = "Run ./run.sh in Alacritty" })

-- Map F7 to run ./compile.sh in Alacritty and keep it open
map("n", "<F7>", function()
  vim.fn.system('alacritty -e bash -c "./compile.sh; exec bash" &')
end, { desc = "Compile ./compile.sh in Alacritty" })
