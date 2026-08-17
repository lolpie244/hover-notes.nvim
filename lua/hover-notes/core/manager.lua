local CategoryManager = {}

local config = require("hover-notes.config")
local constants = require("hover-notes.constants")
local utils = require("hover-notes.utils")

local Category = require("hover-notes.core.category")

local file_categories_map = {}
local ws_categories_map = {}

local workspace_category = nil
local buffer_categories = {}
local loaded_categories = {}

local function get_or_load_category(name)
	if not loaded_categories[name] then
		loaded_categories[name] = Category:new(name)
	end
	return loaded_categories[name]
end

function CategoryManager.setup()
	file_categories_map = utils.load_json(constants.file_map_path) or {}
	ws_categories_map = utils.load_json(constants.ws_map_path) or {}

	workspace_category = ws_categories_map[vim.fn.getcwd()]
end

function CategoryManager.create_category(name, format)
	local category = Category:new(name)
	category:set_format(format)

	loaded_categories[name] = category
	CategoryManager.set_buffer_category(name)

	return category
end

function CategoryManager.delete_category(name)
	local category = get_or_load_category(name)

	if not category then
		return
	end

	category:delete()
	loaded_categories[name] = nil

	workspace_category = nil

	local ws_map_changed = false
	for path, cat_name in pairs(ws_categories_map) do
		if cat_name == name then
			ws_categories_map[path] = nil
			ws_map_changed = true
		end
	end

	for bufnr, cat_name in pairs(buffer_categories) do
		if cat_name == name then
			buffer_categories[bufnr] = nil
		end
	end

	local file_map_changed = false
	for path, cat_name in pairs(file_categories_map) do
		if cat_name == name then
			file_categories_map[path] = nil
			file_map_changed = true
		end
	end

	if file_map_changed then
		utils.save_json(constants.file_map_path, file_categories_map)
	end

	if ws_map_changed then
		utils.save_json(constants.ws_map_path, ws_categories_map)
	end
end

function CategoryManager.get_all_categories()
	local list = {}
	local seen = {}

	local search_pattern = string.format(constants.db_path, "*")
	local files = vim.fn.glob(search_pattern, false, true)

	for _, file in ipairs(files) do
		local name = string.match(file, "([^/\\]+)%.json$")

		if name and name ~= "" and not seen[name] then
			table.insert(list, name)
			seen[name] = true
		end
	end

	for name, _ in pairs(loaded_categories) do
		if not seen[name] then
			table.insert(list, name)
			seen[name] = true
		end
	end

	return list
end

function CategoryManager.set_buffer_category(name)
	local bufnr = vim.api.nvim_get_current_buf()
	buffer_categories[bufnr] = name
end

function CategoryManager.set_workspace_category(name)
	workspace_category = name
	ws_categories_map[vim.fn.getcwd()] = name

	utils.save_json(constants.ws_map_path, ws_categories_map)
end

function CategoryManager.set_file_category(name)
	local filepath = utils.global_filepath(0)
	if filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
		file_categories_map[filepath] = name
		utils.save_json(constants.file_map_path, file_categories_map)
	else
		vim.notify("File does not exists", vim.log.levels.WARN)
	end
end

function CategoryManager.get_current_category()
	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = utils.global_filepath(bufnr)

	local name = nil

	if buffer_categories[bufnr] then
		name = buffer_categories[bufnr]
	elseif filepath ~= "" and file_categories_map[filepath] then
		name = file_categories_map[filepath]
	elseif workspace_category then
		name = workspace_category
	end

	if name then
		return get_or_load_category(name)
	end

	local default_category = config.options.defaultCategory

	if not default_category then
		return nil
	end

	if not loaded_categories[default_category.name] then
		return CategoryManager.create_category(default_category.name, default_category.format)
	end

	return loaded_categories[default_category.name]
end

return CategoryManager
