local nvlsp = require("nvchad.configs.lspconfig")

local function get_cmd(name)
	local path = vim.fn.exepath(name)
	return path ~= "" and path or name
end

vim.lsp.config("*", {
	on_init = nvlsp.on_init,
	on_attach = nvlsp.on_attach,
	capabilities = nvlsp.capabilities,
})

local vue_plugin_path = os.getenv("VUE_PLUGIN_PATH") or "/usr/lib/node_modules/@vue/typescript-plugin"

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
	cmd = { get_cmd("vue-language-server"), "--stdio" },
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

vim.lsp.config("dartls", {
	cmd = { "dart", "language-server", "--client-id", "neovim" },
	root_dir = vim.fs.root(0, { "pubspec.yaml", ".git" }),
	settings = {
		dart = {
			completeFunctionCalls = true,
			showTodos = true,
		},
	},
})

local servers = { "html", "cssls", "tailwindcss", "lua_ls", "jdtls", "sqls", "gopls", "dartls", "slint_lsp", "clangd" }

for _, lsp in ipairs(servers) do
	vim.lsp.config(lsp, {
		cmd = { get_cmd(lsp) },
	})
end

-- Nix LSP
vim.lsp.config("nixd", {
	cmd = { "nixd" },
	filetypes = { "nix" },
	root_dir = vim.fs.root(0, { "flake.nix", ".git" }),
	settings = {
		nixd = {
			nixpkgs = {
				expr = "import <nixpkgs> { }",
			},
			formatting = {
				command = { "alejandra" },
			},
		},
	},
})

-- QML LSP
vim.lsp.config("qmlls", {
	cmd = { "qmlls" },
	filetypes = { "qml" },
	root_dir = vim.fs.root(0, { "qmldir", ".git" }),
})

vim.lsp.config("rust_analyzer", {
	cmd = { get_cmd("rust-analyzer") },
	root_dir = function(filepath)
		local is_flutter_project = vim.fs.root(filepath, "pubspec.yaml")
		if is_flutter_project then
			return vim.fs.root(filepath, { "Cargo.toml", "rust-project.json" })
		else
			return vim.fs.root(filepath, { "Cargo.toml", "rust-project.json", ".git" })
		end
	end,
	settings = {
		["rust-analyzer"] = {
			cargo = { allFeatures = true },
			checkOnSave = true,
			check = { command = "clippy" },
		},
	},
})

vim.lsp.enable({
	"html",
	"cssls",
	"ts_ls",
	"tailwindcss",
	"lua_ls",
	"dartls",
	"gopls",
	"sqls",
	"vue_ls",
	"rust_analyzer",
	"slint_lsp",
	"clangd",
	"nixd",
	"qmlls",
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
