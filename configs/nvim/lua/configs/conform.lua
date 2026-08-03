local options = {
	formatters_by_ft = {
		lua = { "stylua" },
		css = { "oxfmt" },
		html = { "oxfmt" },
		javascript = { "oxfmt" },
		javascriptreact = { "oxfmt" },
		json = { "oxfmt" },
		jsonc = { "oxfmt" },
		typescript = { "oxfmt" },
		typescriptreact = { "oxfmt" },
		vue = { "oxfmt" },
		go = { "goimports", "golines" },
		sql = { "sqlfmt", "sql-formatter" },
		rust = { "rustfmt" },
		toml = { "tombi" },
		cpp = { "clang-format" },
		kotlin = { "ktfmt" },
	},

	format_on_save = {
		timeout_ms = 2000,
		lsp_fallback = true,
	},
}

return options
