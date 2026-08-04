return {
	{
		"mfussenegger/nvim-dap",
		cmd = {
			"DapContinue",
			"DapNew",
			"DapToggleBreakpoint",
			"DapStepOver",
			"DapStepInto",
			"DapStepOut",
			"DapTerminate",
		},
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "Debug: Continue" },
			{ "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle breakpoint" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug: Step over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug: Step into" },
			{ "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step out" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "Debug: Continue" },
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle breakpoint" },
			{ "<leader>do", function() require("dap").step_over() end, desc = "Debug: Step over" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "Debug: Step into" },
			{ "<leader>dx", function() require("dap").terminate() end, desc = "Debug: Terminate" },
		},
		config = function()
			vim.fn.sign_define("DapBreakpoint", {
				text = "●",
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapStopped", {
				text = "▶",
				texthl = "DiagnosticSignWarn",
				linehl = "DapStoppedLine",
				numhl = "",
			})
			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, bg = "#3b3b00" })
		end,
	},
}
