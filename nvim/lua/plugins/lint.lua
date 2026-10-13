-- ~/.config/nvim/lua/plugins/lint.lua
-- nvim-lint corre linters externos y manda los resultados a vim.diagnostic
-- Es distinto al LSP: el LSP analiza mientras escribes, el linter
-- corre herramientas externas (clang-tidy, ruff) en momentos especificos

return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufWritePost" },
        config = function()
            local lint = require("lint")

            lint.linters_by_ft = {
                cpp    = { "clangtidy" },
                c      = { "clangtidy" },
                python = { "ruff" },
            }

            -- Corre el linter al guardar y al entrar a un buffer
            vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
                callback = function()
                    -- Solo si el archivo existe en disco
                    if vim.fn.filereadable(vim.fn.expand("%")) == 1 then
                        lint.try_lint()
                    end
                end,
            })

            -- Keymap para correr lint manualmente
            vim.keymap.set("n", "<leader>ln", function()
                lint.try_lint()
            end, { desc = "Lint: correr linter" })
        end,
    },
}
