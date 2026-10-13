-- ~/.config/nvim/lua/plugins/arduino.lua
-- Integra arduino-cli con nvim para tener LSP en archivos .ino
--
-- REQUISITO: necesitas arduino-language-server instalado
--   mason lo instala automaticamente (esta en ensure_installed de lsp.lua)
--   pero necesitas arduino-cli en tu PATH:
--   https://arduino.github.io/arduino-cli/latest/installation/
--
-- SETUP inicial (correr una vez en terminal):
--   arduino-cli core update-index
--   arduino-cli core install arduino:avr   (para Arduino Uno/Nano)
--   arduino-cli core install arduino:megaavr (para Nano Every)
--
-- compile_commands.json para Arduino:
--   arduino-cli no lo genera solo. El LSP de arduino lo maneja
--   internamente, no necesitas generarlo manualmente.

return {
    {
        "neovim/nvim-lspconfig",  -- ya esta en lsp.lua, lazy deduplica
        ft = { "arduino", "cpp", "c" },
        config = function()
            -- Esta config se fusiona con la de lsp.lua automaticamente
            -- porque lazy.nvim agrupa configs del mismo plugin

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local on_attach = function(client, bufnr)
                local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, {
                        buffer = bufnr,
                        desc   = "Arduino/LSP: " .. desc,
                    })
                end
                map("gd", vim.lsp.buf.definition,  "Go to definition")
                map("K",  vim.lsp.buf.hover,        "Hover docs")
                map("<leader>ca", vim.lsp.buf.code_action, "Code action")

                if client.server_capabilities.documentSymbolProvider then
                    require("nvim-navic").attach(client, bufnr)
                end
            end

            -- arduino-language-server necesita saber que board usas
            -- Cambia "arduino:avr:uno" por tu board:
            --   arduino:avr:nano         -> Arduino Nano
            --   arduino:megaavr:nona4809 -> Arduino Nano Every
            --   arduino:avr:mega         -> Arduino Mega
            -- Para ver tu board: arduino-cli board list
            require("lspconfig").arduino_language_server.setup({
                on_attach    = on_attach,
                capabilities = capabilities,
                cmd = {
                    "arduino-language-server",
                    "-clangd",      vim.fn.exepath("clangd"),
                    "-cli",         vim.fn.exepath("arduino-cli"),
                    "-cli-config",  vim.fn.expand("~/.config/arduino15/arduino-cli.yaml"),
                    "-fqbn",        "arduino:avr:uno", -- CAMBIA ESTO a tu board
                },
            })
        end,
    },

    -- Deteccion de filetype para .ino
    {
        "stevearc/conform.nvim",
        optional = true,
    },
}
