-- ~/.config/nvim/lua/core/keymaps.lua

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ── Navegacion basica ────────────────────────────────────────
-- Mover entre splits con Ctrl + hjkl (sin necesitar Ctrl-W primero)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Redimensionar splits
map("n", "<C-Up>",    ":resize +2<CR>",          opts)
map("n", "<C-Down>",  ":resize -2<CR>",          opts)
map("n", "<C-Left>",  ":vertical resize -2<CR>", opts)
map("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- ── Buffers ──────────────────────────────────────────────────
map("n", "<Tab>",   ":bnext<CR>",     opts)  -- siguiente buffer
map("n", "<S-Tab>", ":bprevious<CR>", opts)  -- buffer anterior
map("n", "<leader>x", ":bdelete<CR>", opts)  -- cerrar buffer actual

-- ── Edicion ──────────────────────────────────────────────────
-- Mover lineas seleccionadas arriba/abajo en visual mode
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Mantener cursor centrado al bajar/subir pagina
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)

-- Pegar sin perder el registro (no sobreescribe lo que copiaste)
map("v", "p", '"_dP', opts)

-- Borrar sin afectar el clipboard
map("n", "x", '"_x', opts)

-- ── Misc ─────────────────────────────────────────────────────
-- Limpiar highlights de busqueda
map("n", "<Esc>", ":nohl<CR>", opts)

-- Guardar rapido
map("n", "<leader>w", ":w<CR>", opts)

-- Salir
map("n", "<leader>q", ":q<CR>", opts)

-- Abrir lazy
map("n", "<leader>l", ":Lazy<CR>", opts)

-- Abrir mason
map("n", "<leader>m", ":Mason<CR>", opts)
