local FloatWindow = {}
FloatWindow.__index = FloatWindow

local config = require("hover-notes.config")

function FloatWindow:new(title, fields)
	local self = setmetatable({}, FloatWindow)
	self:init(title, fields)
	return self
end

function FloatWindow:init(title, fields)
	self.title = title
	self.fields = fields
	self.on_save = on_save

	self.bufnr = vim.api.nvim_create_buf(false, true)
	vim.bo[self.bufnr].filetype = "markdown"
	vim.bo[self.bufnr].bufhidden = "wipe"

	self.parent_win = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(self.parent_win)
	self.cursor_pos = { cursor[1] - 1, cursor[2] }

	self.winnr = vim.api.nvim_open_win(self.bufnr, true, {
		relative = "editor",
		width = 30,
		height = #fields * 2,
		row = math.floor((vim.o.lines - #fields * 2) / 2),
		col = math.floor((vim.o.columns - 30) / 2),
		style = config.options.ui.float.style,
		border = config.options.ui.float.border,
		title = " " .. title .. " ",
		title_pos = "center",
	})

	self.labels_ns = vim.api.nvim_create_namespace("hover_notes_labels")
	self.placeholder_ns = vim.api.nvim_create_namespace("hover_notes_placeholders")

	self:initial_fill()
	self:render()

	self:register_autocmd()
	self:register_keymaps()
end

function FloatWindow:set_modifiable(is_modifiable)
	vim.bo[self.bufnr].modifiable = is_modifiable
end

function FloatWindow:fit_content()
	if not vim.api.nvim_win_is_valid(self.winnr) then
		return
	end

	local max_width = #self.title

	for _, field in ipairs(self.fields) do
		local label_len = #(field.name .. ":")
		if label_len > max_width then
			max_width = label_len
		end
	end

	local buf_lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
	for _, line in ipairs(buf_lines) do
		if #line > max_width then
			max_width = #line
		end
	end

	local target_width = math.min(max_width + 4, vim.o.columns - 4)
	local target_height = math.min(#buf_lines + #self.fields, vim.o.lines - 4)

	vim.api.nvim_win_set_config(self.winnr, {
		relative = "win",
		win = self.parent_win,
		bufpos = self.cursor_pos,
		row = -target_height - 1,
		col = 0,
		width = target_width,
		height = target_height,
	})
end

function FloatWindow:render_labels()
	if not vim.api.nvim_buf_is_valid(self.bufnr) then
		return
	end

	vim.api.nvim_buf_clear_namespace(self.bufnr, self.labels_ns, 0, -1)

	self.label_marks = {}
	for i, field in ipairs(self.fields) do
		local label_row = self.label_rows[i]
		local mark_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.labels_ns, label_row, 0, {
			virt_text = { { field.name .. ":", "Title" } },
			virt_text_pos = "overlay",
		})

		table.insert(self.label_marks, { id = mark_id, name = field.name })
	end
end

function FloatWindow:check_cursor_position()
	local pos = vim.api.nvim_win_get_cursor(0)
	local current_row = pos[1]

	local is_label = false
	local marks = vim.api.nvim_buf_get_extmarks(self.bufnr, self.labels_ns, 0, -1, {})
	for _, mark in ipairs(marks) do
		local mark_row = mark[2] + 1
		if current_row == mark_row then
			is_label = true
			break
		end
	end

	if not is_label then
		self.last_row = current_row
		return
	end

	local target_row

	if self.last_row and current_row < self.last_row then
		target_row = current_row - 1
	else
		target_row = current_row + 1
	end

	local line_count = vim.api.nvim_buf_line_count(self.bufnr)
	if target_row < 1 then
		target_row = 2
	end
	if target_row > line_count then
		target_row = line_count
	end

	pcall(vim.api.nvim_win_set_cursor, 0, { target_row, 0 })
	self.last_row = target_row
end

function FloatWindow:initial_fill()
	local lines = {}
	self.label_rows = {}
	for _, field in ipairs(self.fields) do
		table.insert(self.label_rows, #lines)
		table.insert(lines, "")
		local val = field.value or ""
		local val_lines = type(val) == "string" and vim.split(val, "\n") or val

		for _, vl in ipairs(val_lines) do
			table.insert(lines, vl)
		end
	end
	vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)

	self:render_labels()
end

function FloatWindow:close()
	if vim.api.nvim_win_is_valid(self.winnr) then
		vim.api.nvim_win_close(self.winnr, true)
	end
end

function FloatWindow:render()
	self:fit_content()
end

function FloatWindow:register_autocmd()
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = self.bufnr,
		callback = function()
			self:check_cursor_position()
		end,
	})
end

function FloatWindow:register_keymaps()
	for _, key in ipairs({ "q", "<CR>", "<Esc>" }) do
		vim.keymap.set("n", key, function()
			self:close()
		end, { buffer = self.bufnr, silent = true, desc = "Close Quiz Result" })
	end
end

return FloatWindow
