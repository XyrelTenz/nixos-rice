-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}
M.mappings = require("custom.mappings")

M.base46 = {
	theme = "kanagawa-dragon",
	transparent = true,
	theme_toggle = { "kanagawa-dragon", "kanagawa-dragon" },
}

M.mappings = {
	user = {
		"custom.mappings",
	},
}

M.general = {
	n = {
		["<leader>tt"] = {
			function()
				require("base46").toggle_transparency()
			end,
			"Toggle transparency",
		},
	},
}
-- M.nvdash = { load_on_startup = true }
M.ui = {
	tabufline = {
		enabled = true,
		lazyload = true,
	},
	windbar = {
		enabled = true,
		lazyload = true,
	},
	statusline = {
		-- theme = "minimal",
		-- theme = "vscode_colored",
		theme = "default",
		separator_style = "round",
	},
}

return M
