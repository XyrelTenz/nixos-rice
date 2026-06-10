local options = {
	formatters_by_ft = {
		lua = { "stylua" },
		css = { "prettier" },
		html = { "prettier" },
		kotlin = { "ktfmt" },
		java = { "google_java_format" },
		typescript = { "prettier" },
		vue = { "prettier" },
		go = { "goimports", "golines" },
		rust = { "rustfmt" },
		toml = { "tombi" },
		cpp = { "clang-format" },
		nix = { "alejandra" },
		qml = { "qmlformat" },
	},

	format_on_save = {
		timeout_ms = 2000,
		lsp_fallback = true,
	},

	formatters = {
		stylua = { command = "stylua" },
		prettier = { command = "prettier" },
		ktfmt = { command = "ktfmt" },
		google_java_format = { command = "google-java-format" },
		goimports = { command = "goimports" },
		golines = { command = "golines" },
		rustfmt = { command = "rustfmt" },
		tombi = { command = "tombi" },
		clang_format = { command = "clang-format" },
		alejandra = { command = "alejandra", args = { "-" }, stdin = true },
		qmlformat = { command = "qmlformat", args = { "-" }, stdin = true },
	},
}

return options
