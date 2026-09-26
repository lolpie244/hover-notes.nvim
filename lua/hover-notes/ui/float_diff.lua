local FloatWindow = require("hover-notes.ui.float_window")

local FloatDiff = {}
FloatDiff.__index = FloatDiff

function FloatDiff:new(title, fields, attempt, correct)
	local self = setmetatable({}, FloatDiff)
	self.title = title
	attempt = attempt or {}
	correct = correct or {}

	local left_fields = vim.deepcopy(fields)
	for _, f in ipairs(left_fields) do
		f.value = attempt[f.name] or ""
	end

	local right_fields = vim.deepcopy(fields)
	for _, f in ipairs(right_fields) do
		f.value = correct[f.name] or ""
	end

	self.win_left = FloatWindow:new(" Your Attempt ", left_fields)
	self.win_right = FloatWindow:new(" Correct (" .. title .. ") ", right_fields)

	self.win_left:set_modifiable(false)
	self.win_right:set_modifiable(false)

	self:layout_windows()

	self:register_autocmds()

	vim.api.nvim_win_call(self.win_left.winnr, function()
		vim.cmd("diffthis")
	end)
	vim.api.nvim_win_call(self.win_right.winnr, function()
		vim.cmd("diffthis")
	end)

	return self
end

function FloatDiff:layout_windows()
	local left_width = vim.api.nvim_win_get_width(self.win_left.winnr)

	vim.api.nvim_win_set_config(self.win_right.winnr, {
		relative = "win",
		win = self.win_left.winnr,
		row = -1,
		col = left_width + 1,
	})
end

function FloatDiff:register_autocmds()
	for _, win in ipairs({ self.win_left, self.win_right }) do
		vim.api.nvim_create_autocmd("BufWipeout", {
			buffer = win.bufnr,
			callback = function()
				self:close()
			end,
			once = true,
		})
	end
end

function FloatDiff:close()
	self.win_left:close()
	self.win_right:close()
end

return FloatDiff
