-- ~/.config/nvim/lua/plugins/ui.lua

return {

    -- ── Colorscheme: Gruvbox ─────────────────────────────────
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000, -- carga primero que todo
        config = function()
            require("gruvbox").setup({
                contrast = "hard",       -- fondo mas oscuro
                transparent_mode = false, -- deja que Hyprland maneje el fondo
                overrides = {
                    -- fuerza el fondo a negro puro en los elementos principales
                    Normal          = { bg = "#000000" },
                    NormalNC        = { bg = "#000000" },
                    NormalFloat     = { bg = "#000000" },
                    SignColumn      = { bg = "#000000" },
                    LineNr          = { bg = "#000000" },
                    CursorLineNr    = { bg = "#000000" },
                    EndOfBuffer     = { bg = "#000000" },
                },
            })
            vim.cmd("colorscheme gruvbox")
        end,
    },

    -- ── Statusline: lualine ──────────────────────────────────
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme                = "gruvbox",
                    component_separators = { left = "│", right = "│" },
                    section_separators   = { left = "",  right = "" },
                    globalstatus         = true, -- una sola statusline para todos los splits
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 } }, -- path relativo
                    lualine_x = { "encoding", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end,
    },

    -- ── Buffers como tabs ────────────────────────────────────
    {
        "akinsho/bufferline.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("bufferline").setup({
                options = {
                    mode              = "buffers",
                    separator_style   = "slant",
                    show_buffer_close_icons = true,
                    show_close_icon   = false,
                    diagnostics       = "nvim_lsp",  -- muestra errores LSP en la tab
                    offsets = {
                        {
                            filetype   = "neo-tree",
                            text       = "Files",
                            highlight  = "Directory",
                            separator  = true,
                        },
                    },
                },
            })
        end,
    },

    -- ── File explorer: neo-tree ──────────────────────────────
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch       = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle file explorer" },
            { "<leader>o", ":Neotree focus<CR>",  desc = "Focus file explorer" },
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                window = { width = 30 },
                filesystem = {
                    filtered_items = {
                        visible        = true,  -- muestra dotfiles pero diferente color
                        hide_dotfiles  = false,
                        hide_gitignored = false,
                    },
                    follow_current_file = { enabled = true }, -- sigue el archivo abierto
                },
            })
        end,
    },

    -- ── Indentacion visual ───────────────────────────────────
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            require("ibl").setup({
                indent = { char = "│" },
                scope  = { enabled = true },
            })
        end,
    },

    -- ── Pares de brackets/comillas automaticos ───────────────
    {
        "windwp/nvim-autopairs",
        event  = "InsertEnter",
        config = true,
    },

    -- ── Comentarios rapidos (gcc / gc en visual) ─────────────
    {
        "numToStr/Comment.nvim",
        event  = "BufReadPost",
        config = true,
    },

    -- ── Resalta pares de brackets ────────────────────────────
    {
        "utilyre/barbecue.nvim", -- breadcrumb en la parte superior
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons",
        },
        config = true,
    },
}
