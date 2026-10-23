-- ── Options ──────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local o = vim.opt
o.clipboard = "unnamedplus"
o.number = true
o.relativenumber = true
o.termguicolors = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 8
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.updatetime = 250
o.splitright = true
o.splitbelow = true
o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.wrap = false

vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode with jj" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- :q -> :q! (only when the whole cmdline is exactly "q")
vim.cmd([[cnoreabbrev <expr> q (getcmdtype() == ':' && getcmdline() == 'q') ? 'q!' : 'q']])

-- QML: plain brace-style indenting (treesitter indenter is unreliable for it)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qml",
  callback = function(args)
    local b = vim.bo[args.buf]
    b.indentexpr = ""
    b.cindent = false
    b.smartindent = true
    b.autoindent = true
    b.shiftwidth = 4
    b.tabstop = 4
    b.expandtab = true
  end,
})

-- ── Bootstrap lazy.nvim ──────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ──────────────────────────────────────────────
require("lazy").setup({
  spec = {
    -- Colorscheme
    {
      "navarasu/onedark.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        vim.cmd.colorscheme("onedark")
      end,
    },

    -- Fuzzy finder (master branch: compatible with treesitter `main`)
    {
      "nvim-telescope/telescope.nvim",
      branch = "master",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require("telescope").setup({
          defaults = { file_ignore_patterns = { "node_modules", "%.git/" } },
        })
        local b = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", b.find_files, { desc = "Find files" })
        vim.keymap.set("n", "<leader>fg", b.live_grep, { desc = "Live grep (needs ripgrep)" })
        vim.keymap.set("n", "<leader>fb", b.buffers, { desc = "Buffers" })
        vim.keymap.set("n", "<leader>fh", b.help_tags, { desc = "Help tags" })
      end,
    },

    -- Git
    { "lewis6991/gitsigns.nvim", opts = {} },

    -- UI niceties (icons need a Nerd Font in your terminal)
    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = { options = { theme = "onedark" } },
    },
    { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

    -- Lua LSP knows about the `vim` global etc.
    { "folke/lazydev.nvim", ft = "lua", opts = {} },

    -- Completion
    {
      "saghen/blink.cmp",
      dependencies = { "rafamadriz/friendly-snippets" },
      version = "1.*",
      opts = {
        keymap = { preset = "enter" },
        appearance = { nerd_font_variant = "mono" },
        completion = { documentation = { auto_show = false } },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
        fuzzy = { implementation = "prefer_rust_with_warning" },
      },
      opts_extend = { "sources.default" },
    },

    -- LSP: servers are installed automatically the first time you open a filetype
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "saghen/blink.cmp",
      },
      config = function()
        require("mason").setup()

        vim.lsp.config("*", {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
        })

        -- QML Language Server config
        vim.lsp.config("qml-language-server", {
          cmd = { "qml-language-server" },
          filetypes = { "qml" },
          root_markers = { { "qmldir", "shell.qml" }, ".git" },
        })
        vim.lsp.enable("qml-language-server")

        -- Enables every already-installed server automatically
        require("mason-lspconfig").setup({
          ensure_installed = {},
          automatic_enable = true,
        })

        -- Optional: pick a specific server for a filetype instead of the
        -- first one mason lists, e.g. { python = "basedpyright" }
        local prefer = {}

        local tried = {}
        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("AutoInstallLsp", { clear = true }),
          callback = function(args)
            if vim.bo[args.buf].buftype ~= "" then return end
            local ft = args.match
            if tried[ft] then return end
            tried[ft] = true

            local ok1, ft_map = pcall(require, "mason-lspconfig.mappings.filetype")
            local ok2, srv_map = pcall(require, "mason-lspconfig.mappings.server")
            if not (ok1 and ok2) then return end

            local servers = ft_map[ft]
            if not servers or #servers == 0 then return end
            local server = prefer[ft] or servers[1]
            local pkg_name = srv_map.lspconfig_to_package[server]
            if not pkg_name then return end

            local registry = require("mason-registry")
            local function install()
              local ok, pkg = pcall(registry.get_package, pkg_name)
              if not ok or pkg:is_installed() then return end
              vim.notify(("Installing %s for %s..."):format(pkg_name, ft))
              pkg:install():once("closed", vim.schedule_wrap(function()
                if pkg:is_installed() then
                  vim.lsp.enable(server)
                  vim.notify(pkg_name .. " installed")
                end
              end))
            end

            if registry.get_package and pcall(registry.get_package, pkg_name) then
              install()
            else
              registry.refresh(vim.schedule_wrap(install))
            end
          end,
        })

        vim.diagnostic.config({
          virtual_text = true,
          severity_sort = true,
          float = { border = "rounded" },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(ev)
            local m = function(keys, fn, desc)
              vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
            end
            m("gd", vim.lsp.buf.definition, "Go to definition")
            m("<leader>e", vim.diagnostic.open_float, "Line diagnostics")
            m("<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "Format")
            -- built in on 0.11: K hover, grn rename, gra code action, grr references
          end,
        })
      end,
    },

    -- Treesitter (main branch): parsers install + highlighting start automatically
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        local ts = require("nvim-treesitter")
        ts.setup()

        -- QML: filetype is `qml`, but the parser is called `qmljs`
        vim.treesitter.language.register("qmljs", "qml")
        ts.install({ "qmljs" })

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("AutoTreesitter", { clear = true }),
          callback = function(args)
            local buf = args.buf
            local lang = vim.treesitter.language.get_lang(args.match)
            if not lang then return end

            local function start()
              if not vim.api.nvim_buf_is_valid(buf) then return end
              if not pcall(vim.treesitter.start, buf, lang) then return end

              -- QML uses cindent (see top of file), never the TS indenter
              if lang == "qmljs" then return end

              -- only use TS indenting if the language ships an indents query
              if vim.treesitter.query.get(lang, "indents") then
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end
            end

            if vim.tbl_contains(ts.get_installed(), lang) then
              start()
            elseif vim.tbl_contains(ts.get_available(), lang) then
              ts.install({ lang }):await(vim.schedule_wrap(start))
            end
          end,
        })
      end,
    },
  },

  install = { colorscheme = { "onedark" } },
  checker = { enabled = true, notify = false },
})
