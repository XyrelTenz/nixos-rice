local nvlsp = require("nvchad.configs.lspconfig")
local lspconfig = require("lspconfig")
vim.lsp.config("*", {
	on_init = nvlsp.on_init,
	on_attach = nvlsp.on_attach,
	capabilities = nvlsp.capabilities,
})

local vue_plugin_path = "/usr/lib/node_modules/@vue/typescript-plugin"

vim.lsp.config("ts_ls", {
	filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vue_plugin_path,
				languages = { "vue" },
			},
		},
	},
})

vim.lsp.config("vue_ls", {
	cmd = { "/usr/bin/vue-language-server", "--stdio" },
	on_attach = function(client, bufnr)
		client.server_capabilities.definitionProvider = false
		nvlsp.on_attach(client, bufnr)
	end,
	init_options = {
		vue = {
			hybridMode = true,
		},
	},
})

local servers = { "html", "cssls", "tailwindcss", "luals", "jdtls", "sqls", "gopls", "dartls", "slint_lsp" }

vim.lsp.config("rust_analyzer", {
	cmd = { "rust-analyzer" },

	root_dir = function(filepath)
		local is_flutter_project = vim.fs.root(filepath, "pubspec.yaml")

		local root
		if is_flutter_project then
			root = vim.fs.root(filepath, { "Cargo.toml", "rust-project.json" })
		else
			root = vim.fs.root(filepath, { "Cargo.toml", "rust-project.json", ".git" })
		end
		return root or vim.fs.dirname(filepath)
	end,

	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
			},
			checkOnSave = true,
			check = {
				command = "clippy",
			},
		},
	},
})

vim.lsp.enable({
	"html",
	"cssls",
	"ts_ls",
	"tailwindcss",
	"luals",
	-- "kotlin_lsp",
	-- "kotlin_ls",
	"dartls",
	"jdtls",
	"gopls",
	"sqls",
	"vue_ls",
	"rust_analyzer",
	"slint_lsp",
	"clangd",
})

require("telescope").load_extension("projects")

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local bufnr = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if nvlsp.on_attach then
			nvlsp.on_attach(client, bufnr)
		end

		local opts = { buffer = bufnr }
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)

		vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc"
	end,
})
