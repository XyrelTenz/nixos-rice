require("custom.init")

vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "
-- Deprecated
if vim.lsp.get_clients then
	vim.lsp.buf_get_clients = function(bufnr)
		return vim.lsp.get_clients({ bufnr = bufnr })
	end
end
-- Automatically toggle transparency on VimEnter if not already set
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if not vim.g.transparency then
			require("base46").toggle_transparency()
		end
	end,
})

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require("configs.lazy")

-- load plugins
require("lazy").setup({
	{
		"NvChad/NvChad",
		lazy = false,
		branch = "v2.5",
		import = "nvchad.plugins",
	},

	{ import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require("options")
require("autocmds")

vim.schedule(function()
	require("mappings")
end)

--- Add filetype for Slint files
vim.filetype.add({
	extension = {
		slint = "slint",
	},
})
