local ConfirmDialog = {}
ConfirmDialog.__index = ConfirmDialog

local config = require("hover-notes.config")

function ConfirmDialog:new(prompt, on_confirm)
	self.on_confirm = on_confirm
	self.bufnr = vim.api.nvim_create_buf(false, true)

	local lines = { "", "  " .. prompt .. " (y/n)  ", "" }
	vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)

	local width = #lines[2]
	local height = 3

	self.winnr = vim.api.nvim_open_win(self.bufnr, true, {
		relative = "editor",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		style = config.options.ui.float.style,
		border = config.options.ui.float.border,
		title = " Confirm ",
		title_pos = "center",
	})

    vim.o.guicursor = 'a:noCursor'
    vim.wo[self.winnr].cursorline = false

	vim.bo[self.bufnr].modifiable = false
	vim.bo[self.bufnr].bufhidden = "wipe"

	self:register_keymaps()
end

function ConfirmDialog:close()
	if vim.api.nvim_win_is_valid(self.winnr) then
		vim.api.nvim_win_close(self.winnr, true)
	end
end

function ConfirmDialog:register_keymaps()
	for _, key in ipairs({ "q", "<Esc>", "n" }) do
		vim.keymap.set("n", key, function()
			self:close()
		end, { buffer = self.bufnr, silent = true, desc = "Close Quiz Result" })
	end

	vim.keymap.set("n", "y", function()
		self:close()
		if self.on_confirm then
			self.on_confirm()
		end
	end, { buffer = self.bufnr, nowait = true })
end

return ConfirmDialog
