local FloatWindow = require("hover-notes.ui.float_window")

local FloatEditor = setmetatable({}, { __index = FloatWindow })
FloatEditor.__index = FloatEditor

function FloatEditor:new(title, fields, on_save)
	local self = setmetatable({}, FloatEditor)
	self:init(title, fields, on_save)
	return self
end

function FloatEditor:init(title, fields, on_save)
	FloatWindow.init(self, title, fields)

	self.on_save = on_save

	vim.api.nvim_set_current_win(self.winnr)
	vim.cmd("startinsert")
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

	self:close()

	if self.on_save then
		self.on_save(values)
	end
end

function FloatEditor:render()
	FloatWindow.render(self)
	self:render_placeholders()
end

function FloatEditor:register_autocmd()
	FloatWindow.register_autocmd(self)

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = self.bufnr,
		callback = function()
			self:render()
		end,
	})
end
function FloatEditor:register_keymaps()
	vim.keymap.set("n", "<CR>", function()
		self:save_and_close()
	end, { buffer = self.bufnr, silent = true, desc = "Save and Close FloatEditor" })
end

return FloatEditor
