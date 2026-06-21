local options = {
	formatters_by_ft = {
		lua = { "stylua" },
		css = { "prettier" },
		html = { "prettier" },
		-- dart = { "lsp" },
		kotlin = { "ktfmt" },
		java = { "google_java_format" },
		typescript = { "prettier" },
		vue = { "prettier" },
		go = { "goimports", "golines" },
		sql = { "sqlfmt", "sql-formatter" },
		rust = { "rustfmt" },
		toml = { "tombi" },
		cpp = { "clang-format" },
	},

	format_on_save = {
		timeout_ms = 2000,
		lsp_fallback = true,
	},
}

return options
