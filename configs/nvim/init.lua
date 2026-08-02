require("custom.init")

vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

if vim.lsp.get_clients then
	vim.lsp.buf_get_clients = function(bufnr)
		return vim.lsp.get_clients({ bufnr = bufnr })
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		if not vim.g.transparency then
			require("base46").toggle_transparency()
		end
	end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require("configs.lazy")

require("lazy").setup({
	{
		"NvChad/NvChad",
		lazy = false,
		branch = "v2.5",
		import = "nvchad.plugins",
	},
	{ import = "plugins" },
}, lazy_config)

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require("options")
require("autocmds")

vim.schedule(function()
	require("mappings")
end)

vim.api.nvim_create_autocmd("Filetype", {
  pattern = "dart",
  callback = function()
    vim.opt_local.tabstop = 2      
    vim.opt_local.shiftwidth = 2   
    vim.opt_local.expandtab = true 
  end,
})
