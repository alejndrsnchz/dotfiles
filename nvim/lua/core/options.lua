-- ~/.config/nvim/lua/core/options.lua

local opt = vim.opt

-- ── Apariencia ───────────────────────────────────────────────
opt.number         = true       -- numeros de linea
opt.relativenumber = true       -- numeros relativos (util para saltar lineas)
opt.cursorline     = true       -- resalta linea actual
opt.signcolumn     = "yes"      -- columna para LSP signs (no brinca el texto)
opt.scrolloff      = 8          -- siempre 8 lineas visibles arriba/abajo del cursor
opt.termguicolors  = true       -- colores completos en terminal

-- ── Tabs e indentacion ───────────────────────────────────────
opt.tabstop        = 4          -- tab visual = 4 espacios
opt.shiftwidth     = 4          -- >> y << mueven 4 espacios
opt.softtabstop    = 4          -- tab en insert mode = 4 espacios
opt.expandtab      = true       -- convierte tabs a espacios
opt.autoindent     = true
opt.smartindent    = true

-- ── Busqueda ─────────────────────────────────────────────────
opt.ignorecase     = true       -- busqueda sin distincion mayusculas
opt.smartcase      = true       -- pero si escribes mayusculas, si distingue
opt.hlsearch       = false      -- no resalta todos los resultados al buscar
opt.incsearch      = true       -- resalta mientras escribes

-- ── Splits ───────────────────────────────────────────────────
opt.splitright     = true       -- split vertical abre a la derecha
opt.splitbelow     = true       -- split horizontal abre abajo

-- ── Archivos ─────────────────────────────────────────────────
opt.swapfile       = false      -- sin archivos .swp
opt.backup         = false      -- sin backups
opt.undofile       = true       -- historial de undo persistente entre sesiones

-- ── Misc ─────────────────────────────────────────────────────
opt.mouse          = "a"        -- mouse habilitado
opt.clipboard      = "unnamedplus"  -- clipboard del sistema
opt.wrap           = false      -- sin wrap de lineas largas
opt.updatetime     = 250        -- ms para que se disparen eventos (LSP diagnostics)
opt.timeoutlen     = 300        -- ms para secuencias de teclas
opt.completeopt    = "menuone,noinsert,noselect"
opt.pumheight      = 10         -- max items en menu de autocompletado

-- leader key = espacio
vim.g.mapleader      = " "
vim.g.maplocalleader = " "
