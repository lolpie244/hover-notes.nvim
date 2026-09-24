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
	highlight = {
		enable = true,
		-- if length of words in dictionary is longer than subsstr_match_size_limit use exact word match
		subsstr_match_size_limit = 1000,
		style = { underline = true, sp = vim.api.nvim_get_hl(0, { name = "String", link = false }).fg, bold = true, default = true },
	},
}

function config.set_options(opts)
	opts = opts or {}
	config.options = vim.tbl_deep_extend("force", config.options, opts)
end

return config
