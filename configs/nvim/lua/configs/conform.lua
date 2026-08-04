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
		go = { "gofmt" },
		sql = { "sqlfmt", "sql-formatter" },
		rust = { "rustfmt" },
		toml = { "tombi" },
		cpp = { "clang-format" },
		nix = { "alejandra" },
	},

	format_on_save = {
		timeout_ms = 2000,
		lsp_format = "fallback",
	},
}

return options
