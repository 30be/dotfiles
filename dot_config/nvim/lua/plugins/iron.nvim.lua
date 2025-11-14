return {
  "Vigemus/iron.nvim",
  keys = {
    "<space>ss",
    "<space>ss",
    "<space>sf",
    "<space>sl",
    "<space>su",
    "<space>sm",
    "<space>sb",
    "<space>mc",
    "<space>mc",
    "<space>s<cr>",
    "<space>s<space>",
    "<space>sq",
    "<space>cl",

    { "<space>rs", "<cmd>IronRepl<cr>" },
    { "<space>rr", "<cmd>IronRestart<cr>" },
    { "<space>rf", "<cmd>IronFocus<cr>" },
    { "<space>rh", "<cmd>IronHide<cr>" },
  },
  ft = { "python", "ipynb" },
  config = function()
    local iron = require("iron.core")

    iron.setup({
      config = {
        highlight_last = "IronLastSent",
        scratch_repl = true,
        repl_open_cmd = require("iron.view").split.vertical.botright(0.4),
      },
      keymaps = {
        send_motion = "<space>ss",
        visual_send = "<space>ss",
        send_file = "<space>sf",
        send_line = "<space>sl",
        send_mark = "<space>sm",
        mark_motion = "<space>mc",
        mark_visual = "<space>mc",
        cr = "<space>s<cr>",
        interrupt = "<space>s<space>",
        send_code_block_and_move = "<space>sb",
        exit = "<space>sq",
        clear = "<space>cl",
      },
      highlight = {
        standout = true,
      },
      ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
    })

    -- iron also has a list of commands, see :h iron-commands for all available commands
    vim.keymap.set("n", "<space>rs", "<cmd>IronRepl<cr>")
    vim.keymap.set("n", "<space>rr", "<cmd>IronRestart<cr>")
    vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>")
    vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>")
  end,
}
