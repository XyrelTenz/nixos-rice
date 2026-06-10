vim.diagnostic.config({
	update_in_insert = true,
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "●",
	},
	severity_sort = true,
})

vim.filetype.add({
	extension = {
		js = "javascriptreact",
		ts = "typescriptreact",
	},
})
