local FloatEditor = {}
FloatEditor.__index = FloatEditor

local config = require("hover-notes.config")

function FloatEditor:new(title, fields, on_save)
	local self = setmetatable({}, FloatEditor)
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
	vim.api.nvim_set_current_win(self.winnr)

	self.labels_ns = vim.api.nvim_create_namespace("hover_notes_labels")
	self.placeholder_ns = vim.api.nvim_create_namespace("hover_notes_placeholders")

	self:initial_fill()
	self:render()
	self:register_autocmd()
	self:register_keymaps()

	vim.cmd("startinsert")
	return self
end
function FloatEditor:fit_content()
	if not vim.api.nvim_win_is_valid(self.winnr) then
		return
	end

	local max_width = #self.title

	for _, field in ipairs(self.fields) do
		local label_len = #(field.name .. ":")
		if label_len > max_width then
			max_width = label_len
		end

		if #field.placeholder > max_width then
			max_width = #field.placeholder
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

function FloatEditor:render_labels()
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

function FloatEditor:get_field_bounds(index)
	local mark = self.label_marks[index]
	local pos = vim.api.nvim_buf_get_extmark_by_id(self.bufnr, self.labels_ns, mark.id, {})
	local start_row = pos[1] + 1

	local end_row
	if index < #self.label_marks then
		local next_pos =
			vim.api.nvim_buf_get_extmark_by_id(self.bufnr, self.labels_ns, self.label_marks[index + 1].id, {})
		end_row = next_pos[1] - 1
	else
		end_row = vim.api.nvim_buf_line_count(self.bufnr) - 1
	end

	return start_row, end_row
end

function FloatEditor:render_placeholders()
	if not vim.api.nvim_buf_is_valid(self.bufnr) then
		return
	end

	vim.api.nvim_buf_clear_namespace(self.bufnr, self.placeholder_ns, 0, -1)

	for i, _ in ipairs(self.label_marks) do
		local field = self.fields[i]

		if not field.placeholder then
			goto continue
		end

		local start_row, end_row = self:get_field_bounds(i)

		if start_row == end_row then
			local line_text = vim.api.nvim_buf_get_lines(self.bufnr, start_row, start_row + 1, false)[1]
			if line_text == "" then
				vim.api.nvim_buf_set_extmark(self.bufnr, self.placeholder_ns, start_row, 0, {
					virt_text = { { field.placeholder, "Comment" } },
					virt_text_pos = "overlay",
				})
			end
		end
		::continue::
	end
end

function FloatEditor:check_cursor_position()
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

function FloatEditor:initial_fill()
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

function FloatEditor:get_values()
	local values = {}

	for i, mark in ipairs(self.label_marks) do
		local start_row, end_row = self:get_field_bounds(i)

		local field_lines = vim.api.nvim_buf_get_lines(self.bufnr, start_row, end_row + 1, false)
		values[mark.name:gsub(":$", "")] = table.concat(field_lines, "\n")
	end

	return values
end

function FloatEditor:save_and_close()
    local values = self:get_values()

	if vim.api.nvim_win_is_valid(self.winnr) then
		vim.api.nvim_win_close(self.winnr, true)
	end

	if self.on_save then
		self.on_save(values)
	end
end

function FloatEditor:render()
	self:fit_content()
	self:render_placeholders()
end

function FloatEditor:register_autocmd()
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = self.bufnr,
		callback = function()
			self:render()
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		buffer = self.bufnr,
		callback = function()
			self:check_cursor_position()
		end,
	})
end

function FloatEditor:register_keymaps()
	vim.keymap.set("n", "<CR>", function()
		self:save_and_close()
	end, { buffer = self.bufnr, silent = true, desc = "Save and Close FloatEditor" })
end

return FloatEditor
