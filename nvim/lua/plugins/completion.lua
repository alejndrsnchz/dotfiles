-- ~/.config/nvim/lua/plugins/completion.lua
-- nvim-cmp: autocompletado
-- copilot.lua: GitHub Copilot integrado como fuente de cmp

return {

    -- ── Copilot ──────────────────────────────────────────────
    {
        "zbirenbaum/copilot.lua",
        cmd   = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = { enabled = false }, -- deshabilitamos el inline
                panel      = { enabled = false }, -- usamos cmp en su lugar
            })
        end,
    },

    -- Copilot como fuente de nvim-cmp
    {
        "zbirenbaum/copilot-cmp",
        dependencies = { "zbirenbaum/copilot.lua" },
        config = function()
            require("copilot_cmp").setup()
        end,
    },

    -- ── nvim-cmp ─────────────────────────────────────────────
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",     -- fuente: LSP
            "hrsh7th/cmp-buffer",       -- fuente: palabras del buffer actual
            "hrsh7th/cmp-path",         -- fuente: rutas del sistema de archivos
            "hrsh7th/cmp-cmdline",      -- fuente: comandos de vim
            "saadparwaiz1/cmp_luasnip", -- fuente: snippets
            {
                "L3MON4D3/LuaSnip",         -- motor de snippets
                dependencies = {
                    "rafamadriz/friendly-snippets", -- coleccion de snippets
                },
                build = "make install_jsregexp",
                config = function()
                    require("luasnip.loaders.from_vscode").lazy_load()
                end,
            },
        },
        config = function()
            local cmp     = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },

                window = {
                    completion    = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },

                -- ── Keymaps del menu de autocompletado ───────
                mapping = cmp.mapping.preset.insert({
                    ["<C-k>"]   = cmp.mapping.select_prev_item(),
                    ["<C-j>"]   = cmp.mapping.select_next_item(),
                    ["<C-b>"]   = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"]   = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),  -- fuerza el menu
                    ["<C-e>"]   = cmp.mapping.abort(),       -- cierra el menu
                    ["<CR>"]    = cmp.mapping.confirm({ select = false }), -- confirma solo si seleccionaste
                    ["<Tab>"]   = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),

                -- ── Fuentes en orden de prioridad ─────────────
                sources = cmp.config.sources({
                    { name = "copilot",   group_index = 1 }, -- Copilot primero
                    { name = "nvim_lsp",  group_index = 1 }, -- LSP
                    { name = "luasnip",   group_index = 1 }, -- Snippets
                    { name = "buffer",    group_index = 2 }, -- Palabras del buffer
                    { name = "path",      group_index = 2 }, -- Rutas
                }),

                -- ── Iconos en el menu ─────────────────────────
                formatting = {
                    format = function(entry, item)
                        local icons = {
                            copilot  = " ",
                            nvim_lsp = " ",
                            luasnip  = " ",
                            buffer   = " ",
                            path     = " ",
                        }
                        item.menu = icons[entry.source.name] or ""
                        return item
                    end,
                },
            })

            -- Autocompletado en la linea de comandos
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = { { name = "buffer" } },
            })
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources(
                    { { name = "path" } },
                    { { name = "cmdline" } }
                ),
            })
        end,
    },
}
