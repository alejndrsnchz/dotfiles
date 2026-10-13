-- ~/.config/nvim/lua/plugins/lsp.lua

return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- Mason: instala LSPs, linters, formatters desde nvim
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",

            -- Muestra estado del LSP mientras carga
            { "j-hui/fidget.nvim", opts = {} },

            -- Mejora la UI de LSP (borders, etc)
            "folke/neodev.nvim", -- LSP para el propio config de nvim (lua)
        },
        config = function()
            -- neodev ANTES de lspconfig para que funcione el LSP de lua
            require("neodev").setup()

            -- ── Mason ────────────────────────────────────────
            require("mason").setup({
                ui = { border = "rounded" },
            })

            require("mason-lspconfig").setup({
                ensure_installed = {
                    "clangd",       -- C / C++
                    "pyright",      -- Python
                    "ts_ls",        -- TypeScript / JavaScript
                    "html",         -- HTML
                    "cssls",        -- CSS
                    "lua_ls",       -- Lua (para el config de nvim)
                },
                automatic_installation = true,
            })

            -- ── Keymaps LSP (solo activos cuando hay LSP en el buffer) ──
            local on_attach = function(client, bufnr)
                local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, {
                        buffer = bufnr,
                        desc   = "LSP: " .. desc,
                    })
                end

                map("gd",         vim.lsp.buf.definition,       "Go to definition")
                map("gD",         vim.lsp.buf.declaration,      "Go to declaration")
                map("gr",         vim.lsp.buf.references,       "References")
                map("gi",         vim.lsp.buf.implementation,   "Go to implementation")
                map("K",          vim.lsp.buf.hover,            "Hover docs")
                map("<leader>rn", vim.lsp.buf.rename,           "Rename symbol")
                map("<leader>ca", vim.lsp.buf.code_action,      "Code action")
                map("<leader>d",  vim.diagnostic.open_float,    "Show diagnostic")
                map("[d",         vim.diagnostic.goto_prev,     "Previous diagnostic")
                map("]d",         vim.diagnostic.goto_next,     "Next diagnostic")

                -- Breadcrumb (barbecue/navic) — necesita el cliente
                if client.server_capabilities.documentSymbolProvider then
                    require("nvim-navic").attach(client, bufnr)
                end
            end

            -- ── Capabilities (nvim-cmp se integra aqui) ──────
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- ── Configuracion por servidor ────────────────────
            local lspconfig = require("lspconfig")

            -- C / C++ — clangd con soporte para compile_commands.json
            vim.lsp.config("clangd", {
                on_attach    = on_attach,
                capabilities = capabilities,
                cmd = {
                    "clangd",
                    "--background-index",       -- indexa en segundo plano
                    "--clang-tidy",             -- activa clang-tidy integrado
                    "--header-insertion=never", -- no inserta includes automaticamente
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                },
            })

            vim.lsp.enable("clangd")

            -- CMake
--            vim.lsp.config("cmake",{
--                on_attach    = on_attach,
--                capabilities = capabilities,
--            })
--            vim.lsp.enable("cmake")

            -- Python
            vim.lsp.config("pyright",{
                on_attach    = on_attach,
                capabilities = capabilities,
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode   = "basic", -- "strict" si quieres mas estricto
                            autoSearchPaths    = true,
                            useLibraryCodeForTypes = true,
                        },
                    },
                },
            })
            vim.lsp.enable("pyright")

            -- TypeScript / JavaScript
            vim.lsp.config("ts_ls",{
                on_attach    = on_attach,
                capabilities = capabilities,
            })
            vim.lsp.enable("ts_ls")

            -- HTML
            vim.lsp.config("html",{
                on_attach    = on_attach,
                capabilities = capabilities,
            })
            vim.lsp.enable("html")

            -- CSS
            vim.lsp.config("cssls",{
                on_attach    = on_attach,
                capabilities = capabilities,
            })

            -- Lua (para editar este mismo config)
            vim.lsp.config("lua_ls", {
                on_attach    = on_attach,
                capabilities = capabilities,
                settings = {
                    Lua = {
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            })

            -- ── Diagnostics UI ────────────────────────────────
            vim.diagnostic.config({
                virtual_text   = true,   -- muestra error al lado del codigo
                signs          = true,
                underline      = true,
                update_in_insert = false, -- no molesta mientras escribes
                float = { border = "rounded" },
            })

            -- Iconos en el sign column
            local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
            for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
            end
        end,
    },
}
