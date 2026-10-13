-- ~/.config/nvim/lua/plugins/telescope.lua

return {
    {
        "nvim-telescope/telescope.nvim",
        branch       = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            -- Extension nativa en C, mucho mas rapida para fuzzy find
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
                cond  = function()
                    return vim.fn.executable("make") == 1
                end,
            },
        },
        keys = {
            -- Archivos
            { "<leader>ff", "<cmd>Telescope find_files<cr>",              desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>",               desc = "Live grep (busca texto)" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>",                 desc = "Buffers abiertos" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>",                desc = "Archivos recientes" },
            { "<leader>fs", "<cmd>Telescope grep_string<cr>",             desc = "Busca palabra bajo cursor" },

            -- LSP desde telescope
            { "<leader>fd", "<cmd>Telescope diagnostics<cr>",             desc = "Diagnostics" },
            { "<leader>fk", "<cmd>Telescope keymaps<cr>",                 desc = "Keymaps" },

            -- Git
            { "<leader>gc", "<cmd>Telescope git_commits<cr>",             desc = "Git commits" },
            { "<leader>gb", "<cmd>Telescope git_branches<cr>",            desc = "Git branches" },
            { "<leader>gs", "<cmd>Telescope git_status<cr>",              desc = "Git status" },
        },
        config = function()
            local telescope = require("telescope")
            local actions   = require("telescope.actions")

            telescope.setup({
                defaults = {
                    prompt_prefix   = "   ",
                    selection_caret = "  ",
                    path_display    = { "truncate" },
                    sorting_strategy = "ascending",
                    layout_config = {
                        horizontal = { prompt_position = "top", preview_width = 0.55 },
                    },
                    mappings = {
                        i = {
                            ["<C-k>"] = actions.move_selection_previous,
                            ["<C-j>"] = actions.move_selection_next,
                            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                            ["<Esc>"] = actions.close,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        hidden = true, -- muestra dotfiles
                    },
                },
            })

            telescope.load_extension("fzf")
        end,
    },
}
