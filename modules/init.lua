-- ╔══════════════════════════════════════════════════════════════╗
-- ║  Neovim init.lua                                            ║
-- ║  Native LSP · blink.cmp · fzf-lua · nvim-tree              ║
-- ║  No lspconfig plugin. No mason. No telescope. Pure NixOS.   ║
-- ╚══════════════════════════════════════════════════════════════╝

-- ┌──────────────────────────────────────────────────────────────┐
-- │  1. EDITOR OPTIONS                                          │
-- └──────────────────────────────────────────────────────────────┘

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number         = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.termguicolors  = true
opt.expandtab      = true
opt.shiftwidth     = 4
opt.tabstop        = 4
opt.smartindent    = true
opt.wrap           = false
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.updatetime     = 300
opt.completeopt    = "menuone,noselect,popup"
opt.clipboard      = vim.env.SSH_TTY and "" or "unnamedplus"
opt.undofile       = true
opt.backup         = false
opt.swapfile       = false
opt.splitright     = true
opt.splitbelow     = true
opt.ignorecase     = true
opt.smartcase      = true
opt.mouse          = "a"

-- ┌──────────────────────────────────────────────────────────────┐
-- │  2. THEME                                                   │
-- └──────────────────────────────────────────────────────────────┘

require("catppuccin").setup({
    flavour = "mocha",
    integrations = {
        blink_cmp   = true,
        gitsigns    = true,
        indent_blankline = { enabled = true },
        mini        = { enabled = true },
        nvimtree    = true,
        treesitter  = true,
        which_key   = true,
    },
})
vim.cmd.colorscheme("catppuccin")

-- ┌──────────────────────────────────────────────────────────────┐
-- │  3. NATIVE LSP                                              │
-- │                                                             │
-- │  How it works:                                              │
-- │    vim.lsp.config('name', { ... })  → define a server       │
-- │    vim.lsp.enable('name')           → auto-attach on ft     │
-- │                                                             │
-- │  pyright runs locally from your PATH (installed by Nix).    │
-- │  Zero telemetry. Zero cloud. It just launches the binary    │
-- │  and talks to it over stdio.                                │
-- │                                                             │
-- │  blink.cmp automatically picks up LSP completions.          │
-- └──────────────────────────────────────────────────────────────┘

-- ── Python: pyright ─────────────────────────────────────────────
vim.lsp.config("pyright", {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = {
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "pyrightconfig.json",
        ".git",
    },
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
            },
        },
    },
})

-- ── Lua: lua_ls ─────────────────────────────────────────────────
vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = {
        Lua = {
            runtime  = { version = "LuaJIT" },
            workspace = {
                library = { vim.env.VIMRUNTIME },
                checkThirdParty = false,
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
        },
    },
})

-- ── Nix: nil_ls ─────────────────────────────────────────────────
vim.lsp.config("nil_ls", {
    cmd = { "nil" },
    filetypes = { "nix" },
    root_markers = { "flake.nix", "default.nix", "shell.nix", ".git" },
})

-- ── Enable servers ──────────────────────────────────────────────
vim.lsp.enable("pyright")
vim.lsp.enable("lua_ls")
vim.lsp.enable("nil_ls")

-- ── LSP keymaps on attach ───────────────────────────────────────
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
    callback = function(ev)
        local buf = ev.buf
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = "LSP: " .. desc })
        end

        map("n", "gd",  vim.lsp.buf.definition,      "Go to definition")
        map("n", "gD",  vim.lsp.buf.declaration,      "Go to declaration")
        map("n", "gr",  vim.lsp.buf.references,       "References")
        map("n", "gi",  vim.lsp.buf.implementation,   "Implementation")
        map("n", "gy",  vim.lsp.buf.type_definition,  "Type definition")
        map("n", "K",          vim.lsp.buf.hover,           "Hover docs")
        map("i", "<C-k>",     vim.lsp.buf.signature_help,  "Signature help")
        map("n", "<leader>ca", vim.lsp.buf.code_action,     "Code action")
        map("n", "<leader>cr", vim.lsp.buf.rename,          "Rename symbol")
        map("n", "<leader>cf", function()
            vim.lsp.buf.format({ async = true })
        end, "Format buffer")
        map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
        map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
        map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    end,
})

-- ── Diagnostics config ──────────────────────────────────────────
vim.diagnostic.config({
    underline       = true,
    severity_sort   = true,
    update_in_insert = false,
    float = { border = "rounded", source = true },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN]  = " ",
            [vim.diagnostic.severity.INFO]  = " ",
            [vim.diagnostic.severity.HINT]  = "󰌵 ",
        },
    },
    virtual_text = { prefix = "●", spacing = 4 },
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  4. BLINK.CMP — completion                                  │
-- │                                                             │
-- │  Picks up completions from pyright (and any other LSP)      │
-- │  automatically. Tab/S-Tab to cycle, Enter to confirm.       │
-- └──────────────────────────────────────────────────────────────┘

require("blink.cmp").setup({
    keymap = { preset = "super-tab" },
    appearance = {
        nerd_font_variant = "mono",
        use_nvim_cmp_as_default = true,
    },
    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
        },
        list = {
            selection = { preselect = true, auto_insert = false },
        },
        menu = {
            border = "rounded",
            draw = {
                columns = {
                    { "kind_icon" },
                    { "label", "label_description", gap = 1 },
                    { "kind" },
                },
            },
        },
    },
    sources = {
        default = { "lsp", "snippets", "path", "buffer" },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
    signature = { enabled = true },
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  5. TREESITTER                                              │
-- └──────────────────────────────────────────────────────────────┘

require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent    = { enable = true },
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  6. FZF-LUA — same fzf in terminal and neovim              │
-- │                                                             │
-- │  Write data scripts once → use from terminal with fzf       │
-- │  or from neovim with fzf_exec(). Same tool, same keybinds. │
-- └──────────────────────────────────────────────────────────────┘

local fzf = require("fzf-lua")
fzf.setup({
    winopts = {
        height  = 0.85,
        width   = 0.80,
        row     = 0.35,
        border  = "rounded",
        preview = {
            layout     = "flex",
            horizontal = "right:55%",
            vertical   = "down:45%",
        },
    },
    files = {
        fd_opts = "--type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__",
    },
    grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'",
    },
})

vim.keymap.set("n", "<leader>ff", fzf.files,            { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep,        { desc = "Live grep (rg)" })
vim.keymap.set("n", "<leader>fb", fzf.buffers,          { desc = "Open buffers" })
vim.keymap.set("n", "<leader>fh", fzf.helptags,         { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", fzf.oldfiles,         { desc = "Recent files" })
vim.keymap.set("n", "<leader>fs", fzf.lsp_document_symbols,  { desc = "Document symbols" })
vim.keymap.set("n", "<leader>fw", fzf.lsp_workspace_symbols, { desc = "Workspace symbols" })
vim.keymap.set("n", "<leader>fd", fzf.diagnostics_document,  { desc = "Buffer diagnostics" })
vim.keymap.set("n", "<leader>fD", fzf.diagnostics_workspace, { desc = "Workspace diagnostics" })

-- ── Custom pickers — call your own shell scripts ────────────────
-- Uncomment and adapt these. The pattern:
--   1. Write a shell script that outputs lines (Nix writeShellScriptBin)
--   2. Call it from terminal:  your-script | fzf --preview 'bat {1}'
--   3. Call it from neovim:    fzf.fzf_exec("your-script", { preview = "bat {1}" })
--   ONE script, TWO frontends.
--
-- vim.keymap.set("n", "<leader>fk", function()
--     fzf.fzf_exec("kb", {
--         preview = "bat --color=always --highlight-line {2} {1}",
--         actions = {
--             ["default"] = function(selected)
--                 local file, line = selected[1]:match("([^:]+):(%d+)")
--                 if file then vim.cmd("edit +" .. line .. " " .. file) end
--             end,
--         },
--     })
-- end, { desc = "Knowledge base" })
--
-- vim.keymap.set("n", "<leader>dk", function()
--     fzf.fzf_exec("kpods", { preview = "kubectl describe pod {1}" })
-- end, { desc = "Kubernetes pods" })

-- ┌──────────────────────────────────────────────────────────────┐
-- │  7. FILE TREE — nvim-tree                                   │
-- │                                                             │
-- │  <leader>e  → toggle    a → create    d → delete            │
-- │  <leader>E  → find      r → rename    x → cut   p → paste  │
-- └──────────────────────────────────────────────────────────────┘

require("nvim-tree").setup({
    view = { width = 35, side = "left" },
    renderer = {
        icons = {
            show = { file = true, folder = true, folder_arrow = true, git = true },
        },
        indent_markers = { enable = true },
    },
    filters = {
        dotfiles = false,
        custom = { ".git", "node_modules", "__pycache__" },
    },
    git = { enable = true, ignore = false },
    actions = { open_file = { quit_on_open = false } },
})

vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>",         { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>E", "<cmd>NvimTreeFindFileToggle<cr>", { desc = "Find file in tree" })

-- ┌──────────────────────────────────────────────────────────────┐
-- │  8. MINIMAP — neominimap.nvim (treesitter syntax colors)    │
-- │                                                             │
-- │  Off by default. Toggle on with <leader>mm when you need    │
-- │  to visually scan through logs or find exception blocks.    │
-- │  <leader>mf focuses the minimap for quick scrolling.        │
-- └──────────────────────────────────────────────────────────────┘

vim.g.neominimap = {
    auto_enable = false,

    layout = "split",
    split = { direction = "right", minimap_width = 15 },

    treesitter = { enabled = true },
    diagnostic = { enabled = true, mode = "line" },
    git        = { enabled = true, mode = "sign" },
    search     = { enabled = true, mode = "line" },
    mark       = { enabled = true, mode = "sign" },

    buf_filter = function(bufnr)
        local exclude = { "help", "NvimTree", "dashboard", "Trouble", "lazy", "toggleterm" }
        local ft = vim.bo[bufnr].filetype
        for _, v in ipairs(exclude) do
            if ft == v then return false end
        end
        return true
    end,
}

vim.keymap.set("n", "<leader>mm", "<cmd>Neominimap Toggle<cr>",  { desc = "Toggle minimap" })
vim.keymap.set("n", "<leader>mf", "<cmd>Neominimap Focus<cr>",   { desc = "Focus minimap" })

-- ┌──────────────────────────────────────────────────────────────┐
-- │  9. STATUSLINE                                              │
-- └──────────────────────────────────────────────────────────────┘

require("lualine").setup({
    options = {
        theme = "catppuccin",
        section_separators   = { left = "", right = "" },
        component_separators = { left = "", right = "" },
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  10. GIT SIGNS                                              │
-- └──────────────────────────────────────────────────────────────┘

require("gitsigns").setup({
    signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
    },
    on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = "Git: " .. desc })
        end
        map("n", "]h", gs.next_hunk,     "Next hunk")
        map("n", "[h", gs.prev_hunk,     "Prev hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hr", gs.reset_hunk,   "Reset hunk")
        map("n", "<leader>hb", gs.blame_line,   "Blame line")
    end,
})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  11. SCROLLBAR — always-on, diagnostics + search + git      │
-- │                                                             │
-- │  Thin bar on the right edge. Colored marks show:            │
-- │    red = errors   yellow = warnings   orange = search hits  │
-- │    green/red = git additions/deletions                      │
-- └──────────────────────────────────────────────────────────────┘

require("hlslens").setup()

require("scrollbar").setup({
    handle = { blend = 30 },
    marks = {
        Search = { color = "#ff9e64" },
        Error  = { color = "#db4b4b" },
        Warn   = { color = "#e0af68" },
        Info   = { color = "#0db9d7" },
        Hint   = { color = "#1abc9c" },
        Misc   = { color = "#9d7cd8" },
    },
    excluded_filetypes = {
        "NvimTree", "dashboard", "Trouble", "lazy", "toggleterm", "neominimap",
    },
})

require("scrollbar.handlers.search").setup()
require("scrollbar.handlers.gitsigns").setup()

-- ┌──────────────────────────────────────────────────────────────┐
-- │  12. QUALITY OF LIFE                                        │
-- └──────────────────────────────────────────────────────────────┘

require("ibl").setup({ indent = { char = "│" }, scope = { enabled = true } })
require("nvim-autopairs").setup({})
require("Comment").setup({})
require("which-key").setup({})

-- ┌──────────────────────────────────────────────────────────────┐
-- │  13. KEYMAPS                                                │
-- └──────────────────────────────────────────────────────────────┘

local map = vim.keymap.set

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Right window" })

-- Resize
map("n", "<C-Up>",    "<cmd>resize +2<cr>",          { desc = "Height +" })
map("n", "<C-Down>",  "<cmd>resize -2<cr>",          { desc = "Height -" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Width -" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Width +" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<cr>==",  { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==",  { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv",  { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv",  { desc = "Move selection up" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Misc
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- ┌──────────────────────────────────────────────────────────────┐
-- │  CHEATSHEET (press Space and wait for which-key)            │
-- │                                                             │
-- │  <leader>ff  Find files         <leader>fg  Live grep      │
-- │  <leader>fb  Buffers            <leader>fr  Recent files   │
-- │  <leader>fs  LSP symbols        <leader>fd  Diagnostics    │
-- │  <leader>e   File tree          <leader>E   Find in tree   │
-- │  <leader>mm  Toggle minimap     <leader>mf  Focus minimap  │
-- │  <leader>ca  Code action        <leader>cr  Rename         │
-- │  <leader>cf  Format             <leader>cd  Line diagnostic│
-- │  gd  Definition    gr  References    K  Hover docs         │
-- │  ]d  Next diag     [d  Prev diag    ]h  Next git hunk      │
-- │  gcc  Comment      <C-hjkl>  Window nav   Tab  Completions │
-- └──────────────────────────────────────────────────────────────┘
