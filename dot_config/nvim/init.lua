vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
-- vim.opt.number = true
vim.o.mouse = ""
vim.o.showmode = false
vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
end)
-- vim.opt.laststatus = 3    -- Global statusline (optional, but cleaner for single bar)
vim.opt.cmdheight = 0     -- Hide command line when not typing

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

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.diagnostic.config({
    update_in_insert = false,
    float = { border = "rounded", source = "if_many" },
    underline = { severity = vim.diagnostic.severity.ERROR },
    virtual_lines = true,
})

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
    sqlls = {},
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
    python = { "black" },
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
    "delve",
    "codelldb",
}

local ts_filetypes = {
    "bash",
    "c",
    "cpp",
    "diff",
    "html",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "query",
    "vim",
    "vimdoc",
    "python",
    "javascript",
    "typescript",
    "tsx",
    "rust",
    "toml",
    "json",
    "yaml",
    "haskell",
    "xml",
    "sql",
}

-- Only plugins ahead
require("lazy").setup({
    { "folke/which-key.nvim", opts = { delay = 1000 } },
    "nvim-lua/plenary.nvim", -- Needed everywhere
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
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
            vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
            vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
            vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
            vim.keymap.set({ "n", "v" }, "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
            vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
            vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
            vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
            vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
            vim.keymap.set("n", "<leader>sc", builtin.commands, { desc = "[S]earch [C]ommands" })
            vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("telescope-lsp-attach", { clear = true }),
                callback = function(event)
                    local buf = event.buf
                    vim.keymap.set("n", "grr", builtin.lsp_references, { buffer = buf, desc = "[G]oto [R]eferences" })
                    vim.keymap.set("n", "grd", builtin.lsp_definitions, { buffer = buf, desc = "[G]oto [D]efinition" })
                end,
            })
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
                    map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
                    map("K", vim.lsp.buf.hover, "Hover Documentation")

                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client:supports_method("textDocument/documentHighlight", event.buf) then
                        local highlight_augroup =
                            vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            group = highlight_augroup,
                            callback = vim.lsp.buf.clear_references,
                        })

                        vim.api.nvim_create_autocmd("LspDetach", {
                            group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                            callback = function(event2)
                                vim.lsp.buf.clear_references()
                                vim.api.nvim_clear_autocmds({
                                    group = "kickstart-lsp-highlight",
                                    buffer = event2.buf,
                                })
                            end,
                        })
                    end
                end,
            })

            local capabilities = require("blink.cmp").get_lsp_capabilities()

            -- LSPs: Auto-install using mason-lspconfig (handles name mapping)
            require("mason-lspconfig").setup({
                ensure_installed = vim.tbl_keys(servers or {}),
            })

            -- Formatters: Install using mason-tool-installer
            local ensure_installed = {}
            for _, tools in pairs(formatters) do
                for _, tool in ipairs(tools) do
                    -- Handle package name mismatches
                    if tool == "sql_formatter" then
                        tool = "sql-formatter"
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
        opts = {
            notify_on_error = false,
            formatters_by_ft = formatters,
        },
    },

    {
        "saghen/blink.cmp",
        event = "VimEnter",
        version = "1.*",
        dependencies = {
            {
                "L3MON4D3/LuaSnip",
                version = "2.*",
                build = "make install_jsregexp",
                opts = {},
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
        "echasnovski/mini.statusline",
        version = "*",
        config = function()
            require("mini.statusline").setup()
        end,
    },
    { "folke/tokyonight.nvim", priority = 1000, opts = {} },
    { "folke/todo-comments.nvim", opts = {} },
    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        config = function()
            require("nvim-treesitter").install(ts_filetypes)
            vim.api.nvim_create_autocmd("FileType", {
                pattern = ts_filetypes,
                callback = function()
                    vim.treesitter.start()
                end,
            })
        end,
        lazy = false,
        build = ":TSUpdate",
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,
        config = function()
            require("neo-tree").setup({})
            vim.keymap.set("n", "<C-e>", ":Neotree toggle<CR>", {
                desc = "Toggle Neo-tree file explorer",
                silent = true,
            })
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
        },

        keys = {
            {
                "<M-c>",
                function()
                    require("dap").continue()
                end,
                desc = "Debug: Continue",
            },
            {
                "<M-i>",
                function()
                    require("dap").step_into()
                end,
                desc = "Debug: Step Into",
            },
            {
                "<M-t>",
                function()
                    require("dap").terminate()
                end,
                desc = "Debug: Terminate session",
            },
            {
                "<M-n>",
                function()
                    require("dap").step_over()
                end,
                desc = "Debug: Step Over (Next)",
            },
            {
                "<M-o>",
                function()
                    require("dap").step_out()
                end,
                desc = "Debug: Step Out",
            },
            {
                "<M-b>",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "Debug: Toggle Breakpoint",
            },
            {
                "<M-B>",
                function()
                    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
                end,
                desc = "Debug: Set Breakpoint",
            },
            {
                "<M-u>",
                function()
                    require("dapui").toggle()
                end,
                desc = "Debug: Toggle UI",
            },
            {
                "<M-k>",
                function()
                    require("dap.ui.widgets").hover()
                end,
                desc = "Debug: Hover value",
            },
        },
        config = function()
            local dap, dapui = require("dap"), require("dapui")
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

            -- Assign signs with a "Red Dot" or preferred icon
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
    -- { import = 'dir.filename' },
}, {
    ui = {},
})

vim.cmd.colorscheme("tokyonight-night")

vim.keymap.set("n", "yag", function()
    local view = vim.fn.winsaveview()
    vim.cmd("keepjumps normal! ggyG")
    vim.fn.winrestview(view)
end, { desc = "Yank entire buffer" })
