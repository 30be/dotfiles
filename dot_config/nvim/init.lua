vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.o.showmode = false
vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
end)

vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 150
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.laststatus = 3
vim.o.cursorline = true
vim.o.scrolloff = 5
vim.o.confirm = true
vim.o.expandtab = true
vim.opt.shortmess:append("I") -- no splash

-- Add Mason's bin directory to PATH so vim.lsp.enable() can find the binaries
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. ":" .. vim.env.PATH

vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4

vim.opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,"
    .. "фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"
vim.opt.spelllang = "en_us,ru_ru,de_de"
vim.opt.spell = true

vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim/bin/python3")
local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-t>", "<Esc>", { desc = "Actually send esc to the terminal" })
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    command = "checktime", -- make nvim reload the file when claude changes it
})
vim.api.nvim_create_autocmd("TermRequest", {
    desc = "OSC 7 from Nushell → update cwd + rename terminal buffer",
    callback = function(ev)
        local seq = ev.data.sequence or ""

        -- Extract directory from: \e]7;file://hostname/path\e\\
        local dir, n = string.gsub(seq, "\027]7;file://[^/]*", "")

        if n > 0 and vim.fn.isdirectory(dir) == 1 then
            -- 1. Sync Neovim cwd (Neo-tree follows automatically)
            if vim.api.nvim_get_current_buf() == ev.buf then
                vim.cmd.lcd(dir)
            end

            -- 2. Nice buffer name (this is the part you asked for)
            local nice_path = vim.fn.fnamemodify(dir, ":~") -- ~/projects/foo
            local new_name = "term://" .. nice_path

            -- Safe rename (in case two terminals land on same cwd)
            pcall(vim.api.nvim_buf_set_name, ev.buf, new_name)

            -- Bonus: update term_title for lualine/heirline/statusline
            vim.b[ev.buf].term_title = nice_path
        end
    end,
})
map("n", "H", "<cmd>BufferPrevious<cr>", { desc = "Previous buffer" })
map("n", "L", "<cmd>BufferNext<cr>", { desc = "Next buffer" })

map("n", "Z", function()
    if vim.bo.filetype == "neo-tree" then
        vim.cmd("Neotree close")
        return
    end

    local listed_buffers = vim.tbl_filter(function(buf)
        return vim.fn.buflisted(buf) == 1
    end, vim.api.nvim_list_bufs())

    if #listed_buffers <= 1 then
        vim.cmd("qa")
        return
    end

    -- Switch first, then delete — keeps the window alive
    vim.cmd("BufferPrevious")
    vim.cmd("bdelete #")
    vim.cmd("wincmd =") -- rebalance so Neo-tree stays fixed
end, { desc = "Smart close buffer" })

map("n", "yag", function()
    local view = vim.fn.winsaveview()
    vim.cmd("keepjumps normal! ggyG")
    vim.fn.winrestview(view)
end, { desc = "Yank entire buffer" })

local status_group = vim.api.nvim_create_augroup("TerminalStatusHide", { clear = true })

if vim.fn.argc() == 0 then
    vim.api.nvim_create_autocmd("VimEnter", {
        group = status_group,
        callback = function()
            vim.cmd("terminal")
            vim.cmd("startinsert")
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
            vim.opt_local.list = false
            vim.opt_local.spell = false
        end,
    })
end

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        local bufs = vim.fn.getbufinfo({ buflisted = 1 })
        if #bufs == 0 then
            vim.cmd("quit")
        end
    end,
})

vim.diagnostic.config({
    update_in_insert = false,
    float = { border = "rounded", source = true },
    virtual_text = true,
    severity_sort = true,
})

map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open [D]iagnostics" })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end

local rtp = vim.opt.rtp
rtp:prepend(lazypath)

local servers = {
    clangd = {},
    pyright = {},
    rust_analyzer = {},
    ts_ls = {},
    html = {},
    jsonls = {},
    taplo = {},
    yamlls = {},
    bashls = {},
    lemminx = {},
    hls = {},
    lua_ls = { settings = { Lua = { workspace = { library = { vim.env.VIMRUNTIME } } } } },
}
local formatters = {
    lua = { "stylua" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescriptreact = { "prettierd" },
    python = { "ruff_format" },
    html = { "prettierd" },
    json = { "prettierd" },
    yaml = { "prettierd" },
    markdown = { "prettierd" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    haskell = { "ormolu" },
    rust = { "rustfmt" },
    toml = { "taplo" },
    xml = { "xmlformatter" },
    sql = { "sql_formatter" },
}
local debuggers = {
    "codelldb",
}

local get_compile_fn = function(test_case)
    return function()
        local ft = vim.bo.filetype
        if ft == "cpp" then
            vim.cmd("!printf \\n; cat " .. test_case .. " | ./a.out")
        elseif ft == "python" then
            vim.cmd("!printf \\n; cat " .. test_case .. " | python % ")
        end
    end
end
local dap = function(method)
    return function()
        require("dap")[method]()
    end
end

local dapui = function(method)
    return function()
        require("dapui")[method]()
    end
end

-- Only plugins ahead
require("lazy").setup({
    { "folke/which-key.nvim", opts = { delay = 1000 } },
    "nvim-lua/plenary.nvim", -- Needed everywhere
    { "NMAC427/guess-indent.nvim", opts = {} },
    { "ethanholz/nvim-lastplace", opts = {} },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
        },
        config = function()
            require("telescope").setup({})
            --
            -- See `:help telescope.builtin`
            local builtin = require("telescope.builtin")
            map("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
            map("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
            map("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
            map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
            map({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
            map("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
            map("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
            map("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
            map("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
            map("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
            map("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
        end,
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc, mode)
                        mode = mode or "n"
                        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end
                    map("gr", vim.lsp.buf.rename, "[R]ename")
                    map("ga", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
                    map("K", function()
                        vim.lsp.buf.hover({ border = "rounded" })
                    end, "Hover Documentation")
                end,
            })

            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- LSPs: Auto-install using mason-lspconfig (handles name mapping)
            require("mason-lspconfig").setup({
                ensure_installed = vim.tbl_keys(servers or {}),
            })

            local ensure_installed = {}

            -- TODO: Join the following 2 loops
            for _, tools in pairs(formatters) do
                for _, tool in ipairs(tools) do
                    if tool == "sql_formatter" then
                        tool = "sql-formatter"
                    elseif tool == "ruff_format" or tool == "ruff_fix" or tool == "ruff_organize_imports" then
                        tool = "ruff"
                    end
                    table.insert(ensure_installed, tool)
                end
            end

            require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

            for name, server in pairs(servers) do
                server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                vim.lsp.config(name, server)
                vim.lsp.enable(name)
            end
        end,
    },

    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = "",
                desc = "[F]ormat buffer",
            },
        },
        opts = { formatters_by_ft = formatters },
    },

    {
        "saghen/blink.cmp",
        event = "VimEnter",
        version = "1.*",
        dependencies = {
            {
                "L3MON4D3/LuaSnip",
                build = "make install_jsregexp",
                dependencies = {
                    {
                        "rafamadriz/friendly-snippets",
                        config = function()
                            require("luasnip.loaders.from_vscode").lazy_load()
                            require("luasnip.loaders.from_vscode").lazy_load({
                                paths = { vim.fn.stdpath("config") .. "/snippets" },
                            })
                        end,
                    },
                },
            },
        },
        opts = {
            completion = { documentation = { auto_show = true, auto_show_delay_ms = 500 } },
            sources = { default = { "lsp", "buffer", "path", "snippets" } },
            snippets = { preset = "luasnip" },
            fuzzy = { implementation = "prefer_rust_with_warning" },
            signature = { enabled = true },
        },
    },
    {
        "Mofiqul/vscode.nvim",
        config = function()
            vim.cmd("colorscheme vscode")
        end,
    },
    { "folke/todo-comments.nvim", opts = {} },
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        -- NOTE: Dont forget to call "yay -S tree-sitter-cli"
        config = function()
            require("nvim-treesitter.config").setup({ highlight = { enable = true } })
            require("nvim-treesitter").install({ "python", "markdown", "markdown_inline", "haskell", "sql" })
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
            { "3rd/image.nvim", opts = {} },
        },
        lazy = false,
        opts = {
            filesystem = {
                bind_to_cwd = true,
                cwd_target = {
                    sidebar = "tab",
                    current = "window",
                },
                follow_current_file = { enabled = true },
                use_libuv_file_watcher = true,
                close_if_last_window = true,
            },
            open_files_do_not_replace_types = { "trouble", "qf" },
        },
        config = function(_, opts)
            require("neo-tree").setup(opts)

            map({ "n", "t" }, "<C-e>", function()
                require("neo-tree.command").execute({
                    toggle = true,
                    source = "filesystem",
                    dir = vim.fn.getcwd(),
                    reveal = false,
                    position = "left",
                })
            end, { desc = "Toggle Neo-tree (current cwd)" })
        end,
    },
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "mason-org/mason.nvim",
            "jay-babu/mason-nvim-dap.nvim",
            "mfussenegger/nvim-dap-python",
            "theHamsta/nvim-dap-virtual-text",
        },

        keys = {
            {
                "<M-c>",
                function()
                    local dap = require("dap")
                    if dap.session() then
                        dap.continue()
                    else
                        local configs = dap.configurations[vim.bo.filetype]
                        if configs and configs[1] then
                            dap.run(configs[1])
                        else
                            dap.continue()
                        end
                    end
                end,
                desc = "Debug: Continue",
            },
            { "<M-i>", dap("step_into"), desc = "Debug: Step Into" },
            { "<M-t>", dap("terminate"), desc = "Debug: Terminate session" },
            { "<M-n>", dap("step_over"), desc = "Debug: Step Over (Next)" },
            { "<M-o>", dap("step_out"), desc = "Debug: Step Out" },
            { "<M-b>", dap("toggle_breakpoint"), desc = "Debug: Toggle Breakpoint" },
            { "<M-u>", dapui("toggle"), desc = "Debug: Toggle UI" },
            {
                "<M-B>",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "Debug: Set Breakpoint",
            },

            { "<M-1>", get_compile_fn("in1"), desc = "Debug: run on test 1" },
            { "<M-2>", get_compile_fn("in2"), desc = "Debug: run on test 2" },
            { "<M-3>", get_compile_fn("in3"), desc = "Debug: run on test 3" },
            { "<M-4>", get_compile_fn("in4"), desc = "Debug: run on test 4" },
            {
                "<M-p>",
                function()
                    vim.cmd("!clang++ -g %")
                end,
                desc = "Debug: Compile",
            },
            {
                "<M-k>",
                function()
                    local widgets = require("dap.ui.widgets")
                    if _G.dap_hover_win and vim.api.nvim_win_is_valid(_G.dap_hover_win) then
                        vim.api.nvim_set_current_win(_G.dap_hover_win)
                    else
                        local prev = vim.api.nvim_get_current_win()
                        _G.dap_hover_win = widgets.hover(nil, { border = "rounded" }).win
                        vim.api.nvim_set_current_win(prev)
                        vim.api.nvim_create_autocmd("CursorMoved", {
                            buffer = 0,
                            once = true,
                            callback = function()
                                if vim.api.nvim_win_is_valid(_G.dap_hover_win) then
                                    vim.api.nvim_win_close(_G.dap_hover_win, true)
                                end
                                _G.dap_hover_win = nil
                            end,
                        })
                    end
                end,
                desc = "Debug: Hover value",
            },
        },
        config = function()
            local dap, dapui = require("dap"), require("dapui")
            require("nvim-dap-virtual-text").setup({})
            require("mason-nvim-dap").setup({
                automatic_installation = true,
                handlers = {},
                ensure_installed = debuggers,
            })
            dapui.setup({})
            dap.listeners.after.event_initialized["dapui_config"] = dapui.open
            dap.listeners.before.event_terminated["dapui_config"] = dapui.close
            dap.listeners.before.event_exited["dapui_config"] = dapui.close
            -- Define high-visibility colors
            vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e06c75", bg = "NONE" }) -- Red
            vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef", bg = "NONE" }) -- Blue
            vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379", bg = "NONE" }) -- Green

            local signs = {
                DapBreakpoint = { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" },
                DapBreakpointCondition = { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" },
                DapLogPoint = { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" },
                DapStopped = { text = "▶", texthl = "DapStopped", linehl = "Visual", numhl = "DapStopped" },
            }

            for name, config in pairs(signs) do
                vim.fn.sign_define(name, config)
            end

            -- Setup python debugger
            local python_path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
            require("dap-python").setup(python_path)
        end,
    },
    { -- Make Esc work in claude code
        "folke/snacks.nvim",
        opts = { terminal = { win = { keys = { term_normal = false } } } },
    },

    {
        "coder/claudecode.nvim",
        dependencies = { "folke/snacks.nvim" },
        opts = {
            diff_opts = {
                open_in_new_tab = true,
            },
        },
        keys = {
            { -- Jiggle to fix wrong cursor position
                "<M-a>",
                function()
                    vim.cmd("ClaudeCode")
                    vim.defer_fn(function()
                        local win = vim.api.nvim_get_current_win()
                        local h = vim.api.nvim_win_get_height(win)
                        if h >= 2 then
                            vim.api.nvim_win_set_height(win, h - 1)
                            vim.defer_fn(function()
                                if vim.api.nvim_win_is_valid(win) then
                                    vim.api.nvim_win_set_height(win, h)
                                end
                            end, 10)
                        end
                    end, 30)
                end,
                mode = { "v", "n", "t" },
                desc = "Toggle Claude",
            },
            { "<M-s>", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
            {
                "<M-s>",
                "<cmd>ClaudeCodeTreeAdd<cr>",
                desc = "Add file",
                ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
            },
            { "<M-s>", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
            { "<M-y>", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
            { "<M-r>", "<cmd>ClaudeCodeDiffDeny<cr><cmd>ClaudeCodeFocus<cr>", desc = "Reject diff" },
        },
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app; yarn install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },

    { "jghauser/follow-md-links.nvim" }, -- follow links on enter
    { "catgoose/nvim-colorizer.lua", event = "BufReadPre", opts = {} },
    { "nvim-lualine/lualine.nvim", dependencies = "nvim-tree/nvim-web-devicons", opts = {} },
    { "nvim-mini/mini.cursorword", version = "*", opts = {} }, -- underline the word under cursor
    { "Weissle/persistent-breakpoints.nvim", opts = { load_breakpoints_event = { "BufReadPost" } } },

    {
        "3rd/image.nvim",
        opts = {
            window = {
                mappings = {
                    ["P"] = {
                        "toggle_preview",
                        config = {
                            use_float = false,
                            use_image_nvim = true,
                            -- use_snacks_image = true,
                            -- title = 'Neo-tree Preview',
                        },
                    },
                },
            },
        },
    },
    {
        "romgrk/barbar.nvim",
        dependencies = { "lewis6991/gitsigns.nvim", "nvim-tree/nvim-web-devicons" },
        opts = { auto_hide = true },
    },
    { "chentoast/marks.nvim", event = "VimEnter", opts = {} },
    {
        "michaelb/sniprun",
        build = "sh install.sh",
        opts = {},
        keys = { { "<leader>r", ":SnipRun<cr>", mode = { "v", "n" }, desc = "Run snippet" } },
    },
}, {
    ui = {},
})
