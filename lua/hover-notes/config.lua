local config = {}

config.options = {
	notesDir = vim.fn.stdpath("data") .. "/hover-notes", -- the root directory where all notes are stored
	defaultCategory = { -- the default note category
		name = "Default",
		format = "{text}",
	},
	ui = { -- style of the float window
		float = {
			style = "minimal",
			border = "rounded",
		},
	},
}

function config.set_options(opts)
	opts = opts or {}
	config.options = vim.tbl_deep_extend("force", config.options, opts)
end

return config
