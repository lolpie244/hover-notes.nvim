if vim.g.loaded_hover_notes then
	return
end
vim.g.loaded_hover_notes = true

local command = vim.api.nvim_create_user_command
local hover = require("hover-notes")
local utils = require("hover-notes.utils")

local function get_word(opts)
	if opts.args and opts.args ~= "" then
		return opts.args
	elseif opts.range > 0 then
		return utils.get_command_visual_selection()
	else
		return vim.fn.expand("<cword>")
	end
end

command("HNShow", function(opts)
	hover.show_note(get_word(opts))
end, {
	nargs = "?",
	range = true,
})

command("HNEdit", function(opts)
	hover.add_edit_note(get_word(opts))
end, {
	nargs = "?",
	range = true,
})

command("HNDeleteNote", function(opts)
	hover.delete_note(get_word(opts))
end, {
	nargs = "?",
	range = true,
})

command("HNCreateCategory", function(opts)
	hover.create_category(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
})

command("HNDeleteCategory", function(opts)
	hover.delete_category(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
})

command("HNSetWorkspace", function(opts)
	hover.set_workspace_category(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
})

command("HNSetBuffer", function(opts)
	hover.set_buffer_category(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
})

command("HNSetFile", function(opts)
	hover.set_file_category(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
})

command("HNGetCategory", function(opts)
	vim.notify("Current category " .. hover.get_category(), vim.log.levels.INFO)
end, {
	nargs = "?",
})

vim.api.nvim_create_user_command("HNQuiz", function(opts)
	hover.quiz_mode(get_word(opts))
end, {
	nargs = "?",
})
