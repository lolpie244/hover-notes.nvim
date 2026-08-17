if vim.g.loaded_hover_notes then
	return
end
vim.g.loaded_hover_notes = true

local command = vim.api.nvim_create_user_command
local hover = require("hover-notes")

command("HNShow", function(opts)
	hover.show_note()
end, {})

command("HNEdit", function(opts)
	hover.add_edit_note(opts.args ~= "" and opts.args or nil)
end, {
	nargs = "?",
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
