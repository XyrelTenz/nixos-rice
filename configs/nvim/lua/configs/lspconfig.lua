local nvlsp = require("nvchad.configs.lspconfig")
vim.lsp.config("*", {
	on_init = nvlsp.on_init,
	on_attach = nvlsp.on_attach,
	capabilities = nvlsp.capabilities,
})

local vue_plugin_path = "/usr/lib/node_modules/@vue/typescript-plugin"

vim.lsp.config("nixd", {
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", "default.nix", ".git" },
	settings = {
		nixd = {
			nixpkgs = {
				expr = "import <nixpkgs> { }",
			},
			formatting = {
				command = { "alejandra" },
			},
			options = {
				nixos = {
					expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.XyrelTenz.options",
				},
				["home-manager"] = {
					expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.XyrelTenz.options.home-manager.users.type.getSubOptions []",
				},
			},
		},
	},
})

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

vim.lsp.config("oxlint", {
	cmd = { "oxlint", "--lsp" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
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

vim.lsp.config("rust_analyzer", {
	cmd = { "rust-analyzer" },

	root_dir = function(bufnr, on_dir)
		local filepath = vim.api.nvim_buf_get_name(bufnr)

		local cargo_registry = vim.fn.expand("~/.cargo/registry")
		local rustup_home = vim.fn.expand("~/.rustup")
		if
			vim.startswith(filepath, cargo_registry)
			or vim.startswith(filepath, rustup_home)
			or vim.startswith(filepath, "/rustc")
			or vim.startswith(filepath, "/nix/store")
		then
			local clients = vim.lsp.get_clients({ name = "rust_analyzer" })
			if #clients > 0 then
				on_dir(clients[1].config.root_dir)
				return
			end
			on_dir(vim.fn.getcwd())
			return
		end

		local root = vim.fs.root(bufnr, { "Cargo.toml", "rust-project.json", ".git" })

		local final_root = root or (filepath ~= "" and vim.fs.dirname(filepath)) or vim.fn.getcwd()
		if final_root then
			on_dir(final_root)
		end
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
	"nixd",
	"ts_ls",
	"oxlint",
	"tailwindcss",
	"luals",
	"gopls",
	"sqls",
	"vue_ls",
	"rust_analyzer",
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
		vim.keymap.set("n", "gd", function()
			local ok, err = pcall(vim.lsp.buf.definition)
			if not ok then
				vim.notify("LSP not ready yet: " .. tostring(err), vim.log.levels.WARN)
			end
		end, opts)

		vim.bo[bufnr].tagfunc = "v:lua.vim.lsp.tagfunc"
	end,
})
