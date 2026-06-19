require("nvchad.autocmds")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.toml.tmpl", "*.tmpl", "*.jsonc.tmpl" },
	callback = function(ev)
		if ev.file:match("%.toml%.tmpl$") then
			vim.bo.filetype = "toml"
		elseif ev.file:match("%.jsonc%.tmpl$") then
			vim.bo.filetype = "jsonc"
		elseif ev.file:match("ghostty.*%.tmpl$") then
			vim.bo.filetype = "toml"
		else
			vim.bo.filetype = "toml"
		end
	end,
})
