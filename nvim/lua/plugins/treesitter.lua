-- ~/.config/nvim/lua/plugins/treesitter.lua

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",

        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
        },

        config = function()
            require("nvim-treesitter").install({
                "c",
                "cpp",
                "cmake",
                "python",
                "javascript",
                "typescript",
                "html",
                "css",
                "lua",
                "bash",
                "json",
                "yaml",
                "toml",
                "markdown",
                "markdown_inline",
            })

            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",

        config = function()
            require("nvim-treesitter-textobjects").setup({
                select = {
                    lookahead = true,
                },
                move = {
                    set_jumps = true,
                },
            })

            local select = require("nvim-treesitter-textobjects.select")
            local move = require("nvim-treesitter-textobjects.move")

            local function select_textobject(query)
                return function()
                    select.select_textobject(query, "textobjects")
                end
            end

            -- Select
            vim.keymap.set({ "x", "o" }, "af",
                select_textobject("@function.outer"))
            vim.keymap.set({ "x", "o" }, "if",
                select_textobject("@function.inner"))

            vim.keymap.set({ "x", "o" }, "ac",
                select_textobject("@class.outer"))
            vim.keymap.set({ "x", "o" }, "ic",
                select_textobject("@class.inner"))

            vim.keymap.set({ "x", "o" }, "aa",
                select_textobject("@parameter.outer"))
            vim.keymap.set({ "x", "o" }, "ia",
                select_textobject("@parameter.inner"))

            -- Move
            vim.keymap.set({ "n", "x", "o" }, "]f", function()
                move.goto_next_start("@function.outer", "textobjects")
            end)

            vim.keymap.set({ "n", "x", "o" }, "[f", function()
                move.goto_previous_start("@function.outer", "textobjects")
            end)

            vim.keymap.set({ "n", "x", "o" }, "]c", function()
                move.goto_next_start("@class.outer", "textobjects")
            end)

            vim.keymap.set({ "n", "x", "o" }, "[c", function()
                move.goto_previous_start("@class.outer", "textobjects")
            end)
        end,
    },
}
