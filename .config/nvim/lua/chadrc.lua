local M = {}
M.mappings = require("custom.mappings")

M.base46 = {
	theme = "chadtain",
	transparent = true,
	theme_toggle = { "chadtain", "chadtain" },
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
		theme = "default",
		separator_style = "round",
	},
}

return M