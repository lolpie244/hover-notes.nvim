local M = {}

local config = require("hover-notes.config")
local utils = require("hover-notes.utils")
local constants = require("hover-notes.constants")

local ui = require("hover-notes.ui")
local manager = require("hover-notes.core.manager")

function M.setup(opts)
	config.set_options(opts)
	constants.setup()
	manager.setup()

	if vim.fn.isdirectory(config.options.notesDir) == 0 then
		vim.fn.mkdir(config.options.notesDir, "p")
	end
end

function M.create_category(name)
	local function prompt_format(cat_name)
		local fields = {
			{
				name = "Format",
				placeholder = "etc. Word: {word} | Meaning: {meaning}",
			},
		}

		ui.open_float_editor("Create Category: " .. cat_name, fields, function(values)
			manager.create_category(cat_name, values["Format"])
			vim.notify("Category '" .. cat_name .. "' created!", vim.log.levels.INFO)
		end)
	end

	if not name then
		vim.ui.input({ prompt = "New Category Name: " }, function(input)
			if input and input ~= "" then
				prompt_format(input)
			end
		end)
	else
		prompt_format(name)
	end

	return name
end

function M.show_note(word)
	local cat = manager.get_current_category()
	if not cat then
		return
	end

	word = vim.trim(word or vim.fn.expand("<cword>")):lower()

	local msg, word = cat:get_note(word)
	if not msg then
		return
	end

	ui.show_hover(word, msg)
end

function M.add_edit_note(word)
	local cat = manager.get_current_category()
	if not cat then
		vim.notify("No active category!", vim.log.levels.WARN)
		return
	end

	word = vim.trim(word or vim.fn.expand("<cword>")):lower()
	if not word or word == "" then
		return
	end

	local current_vars = cat.db:get(word) or {}

	local fields = {}
	for _, field_name in ipairs(cat.fields) do
		table.insert(fields, {
			name = field_name,
			value = current_vars[field_name] or "",
			placeholder = "Enter " .. field_name .. "...",
		})
	end
	ui.open_float_editor("Edit Note: " .. word, fields, function(values)
		local new_vars = {}
		for _, field_name in ipairs(cat.fields) do
			new_vars[field_name] = vim.trim(values[field_name] or "")
		end

		cat:set_note(word, new_vars)
		vim.notify("Saved note for '" .. word .. "'", vim.log.levels.INFO)
	end)
end

local function select_category(name, action_fn, include)
	if name then
		action_fn(name)
	else
		local categories = utils.merge_arrays(include, manager.get_all_categories())
		ui.select("Select category", categories, function(item)
			action_fn(item)
		end)
	end
end

function M.set_workspace_category(name)
	select_category(name, function(cat_name)
		if cat_name == "Create new category" then
			cat_name = M.create_category(nil)
		end
		manager.set_workspace_category(cat_name)
	end, { "Create new category" })
end

function M.set_buffer_category(name)
	select_category(name, function(cat_name)
		if cat_name == "Create new category" then
			cat_name = M.create_category(nil)
		end
	end, { "Create new category" })
end

function M.set_file_category(name)
	select_category(name, function(cat_name)
		if cat_name == "Create new category" then
			cat_name = M.create_category(nil)
		end
	end, { "Create new category" })
end

function M.delete_category(name)
	select_category(name, function(cat_name)
		manager.delete_category(cat_name)
	end, {})
end
return M
