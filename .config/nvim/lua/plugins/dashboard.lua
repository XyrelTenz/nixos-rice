local function buildRgCmd(opts)
	local expression = "(" .. table.concat(opts.sign_list, "|") .. "):?"

	if opts.match_comment_symbols then
		expression = [[([^\S\r\n]*(]]
			.. table.concat(opts.comment_symbols, "|")
			.. [[)[^\S\r\n]*)\s*(]]
			.. table.concat(opts.sign_list, "|")
			.. [[):?\s*]]
	end

	local rg_command = "rg --binary-files=without-match --no-heading --color never "
		.. "-g '!{**/node_modules/*,**/.git/*,**/build/*,**/.gradle/*}' "
		.. "-w '"
		.. expression
		.. "' "
		.. table.concat(opts.dirs, " ")
		.. " --hidden --follow --line-number --column --with-filename"

	return rg_command
end

local function getTodos(opts)
	if next(opts.sign_list) == nil then
		return {}
	end

	local rg_command = buildRgCmd(opts)
	local rg_res = vim.fn.systemlist(rg_command)
	local todos = {}
	local todo_count = 0

	for i, line in ipairs(rg_res) do
		local filename, row, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")

		if filename and row and col and text then
			todo_count = todo_count + 1
			local sign_sym = ""

			for _, sign_s in ipairs(opts.sign_list) do
				local start_pos, end_pos = text:find(sign_s .. ":")
				if start_pos then
					sign_sym = text:sub(start_pos, end_pos)
					text = text:sub(end_pos + 1)
				end
			end

			local todo = {
				index = (i + 5 ~= 10) and (i + 5) or 0,
				file = filename:match("^%s*(.-)%s*$"),
				line = row,
				column = col,
				sign = sign_sym,
				desc = text:match("^%s*(.-)%s*$"),
			}
			table.insert(todos, todo)

			if todo_count >= opts.limit then
				break
			end
		end
	end

	return todos
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		dashboard = {
			width = 75,
			pane_gap = 10,
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
			preset = {
				keys = {
					{
						icon = " ",
						key = "f",
						desc = "Files",
						hidden = true,
						action = ":lua Snacks.dashboard.pick('files')",
					},
					{ icon = " ", key = "d", desc = "Database", hidden = true, action = "SQLua" },
					{
						icon = " ",
						key = "r",
						desc = "Recent",
						hidden = true,
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						hidden = true,
						action = function()
							require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
						end,
					},
					{ icon = "󰒲 ", key = "l", desc = "Lazy", hidden = true, action = ":Lazy" },
					{ icon = " ", key = "q", desc = "Quit", hidden = true, action = ":qa" },
				},
			},
			formats = {
				key = { "" },
				file = function(item)
					return {
						{ item.key, hl = "key" },
						{ " " },
						{ item.file:sub(2):match("^(.*[/])") or "", hl = "NonText" },
						{ item.file:match("([^/]+)$") or item.file, hl = "Normal" },
					}
				end,
				icon = { "" },
			},
			sections = {
				{ section = "keys" },
				{
					pane = 1,
					section = "terminal",
					cmd = "img2art ~/.config/nvim/images/hq.png --threshold 40 --scale .34 --quant 16 --with-color",
					height = 27,
					width = 100,
					indent = 0,
				},
				{
					pane = 2,
					indent = 15,
					{
						{ section = "startup", padding = 1 },
						{ text = "" },
						{
							text = {
								{ "    ", hl = "DiagnosticHint" },
								{ "[F] Files", hl = "Normal" },
								{ "", width = 20 },
								{ "    ", hl = "Number" },
								{ "[D] Database", hl = "Normal" },
							},
						},
						{ text = "", padding = 1 },
						{
							text = {
								{ "    ", hl = "DiagnosticHint" },
								{ "[R] Recent", hl = "Normal" },
								{ "", width = 19 },
								{ "    ", hl = "Number" },
								{ "[C] Config", hl = "Normal" },
							},
						},
						{ text = "", padding = 1 },
						{
							text = {
								{ "󰒲    ", hl = "Label" },
								{ "[L] Lazy", hl = "Normal" },
								{ "", width = 21 },
								{ "    ", hl = "Number" },
								{ "[Q] Quit", hl = "Normal" },
							},
						},
					},
					{ text = "", padding = 2 },
					{ title = "Projects", padding = 1, indent = 15 },
					{ section = "projects", limit = 5, padding = 2, indent = 15 },
					{ title = "Recent Files", padding = 1, indent = 15 },
					{ section = "recent_files", limit = 8, padding = 2, indent = 15 },
				},
			},
		},
		bigfile = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		lazygit = { enabled = true },
		notifier = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},
	config = function(_, opts)
		require("snacks").setup(opts)

		local nvc_color = vim.api.nvim_get_hl(0, { name = "FolderIcon" })
		vim.api.nvim_set_hl(0, "SnacksDashboardSpecial", { fg = nvc_color.fg })
	end,
}
