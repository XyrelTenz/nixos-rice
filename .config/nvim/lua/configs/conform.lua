local options = {
	formatters_by_ft = {
		lua = { "stylua" },
		css = { "prettier" },
		html = { "prettier" },
		typescript = { "prettier" },
		vue = { "prettier" },
		go = { "goimports", "golines" },
		sql = { "sqlfmt", "sql-formatter" },
		rust = { "rustfmt" },
		toml = { "tombi" },
		cpp = { "clang-format" },
		prisma = { "prisma-fmt" },
	},

	format_on_save = {
		timeout_ms = 2000,
		lsp_fallback = true,
	},
}

return options
