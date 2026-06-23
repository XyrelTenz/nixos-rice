return {
	"notjedi/nvim-rooter.lua",
	config = function()
		require("nvim-rooter").setup({
			update_cwd = true,
			trigger_patterns = { "*" },
			rooter_patterns = {
				".git",
				".hg",
				".svn",
				"build.gradle.kts",
				"settings.gradle.kts",
				"module.yaml",
				"amper.bat",
				"amper.sh",
				".agent",
				"rust-project.json",
			},
		})
	end,
}
