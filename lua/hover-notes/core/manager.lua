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
local loaded_workspace_categories = {}

local function get_default_name()
	return config.options.defaultCategory and config.options.defaultCategory.name or "Default"
end

local function get_default_format()
	return config.options.defaultCategory and config.options.defaultCategory.format or "{text}"
end

local function is_default_category(name)
	if not name then
		return false
	end
	local def_name = get_default_name()
	return name == def_name or name:lower() == "default" or name:lower() == def_name:lower()
end

function CategoryManager.get_workspace_path()
	return vim.fs.normalize(vim.fn.getcwd())
end

function CategoryManager.get_workspace_id(ws_path)
	ws_path = ws_path or CategoryManager.get_workspace_path()
	local base = vim.fs.basename(ws_path)
	if not base or base == "" then
		base = "root"
	end
	local safe_base = base:gsub("[^%w._-]", "_")
	local hash = vim.fn.sha256(ws_path):sub(1, 10)
	return safe_base .. "_" .. hash
end

function CategoryManager.get_workspace_default_category(ws_path)
	ws_path = ws_path or CategoryManager.get_workspace_path()

	if loaded_workspace_categories[ws_path] then
		return loaded_workspace_categories[ws_path]
	end

	local ws_id = CategoryManager.get_workspace_id(ws_path)
	local db_path = string.format(constants.ws_db_path, ws_id)
	local default_name = get_default_name()
	local default_format = get_default_format()

	local category = Category:new(default_name, db_path)
	if not category.format or category.format == "" then
		category:set_format(default_format)
	end
	category.workspace_path = ws_path

	loaded_workspace_categories[ws_path] = category
	return category
end

local function get_or_load_category(name)
	if not name or is_default_category(name) then
		return CategoryManager.get_workspace_default_category()
	end

	if not loaded_categories[name] then
		loaded_categories[name] = Category:new(name)
	end
	return loaded_categories[name]
end

function CategoryManager.setup()
	file_categories_map = utils.load_json(constants.file_map_path) or {}
	ws_categories_map = utils.load_json(constants.ws_map_path) or {}

	workspace_category = ws_categories_map[CategoryManager.get_workspace_path()]
end

function CategoryManager.create_category(name, format)
	local category = Category:new(name)
	category:set_format(format)
	category.db:save()

	loaded_categories[name] = category
	CategoryManager.set_buffer_category(name)

	return category
end

function CategoryManager.delete_category(name)
	local is_default = is_default_category(name)
	local ws_path = CategoryManager.get_workspace_path()

	local category
	if is_default then
		category = CategoryManager.get_workspace_default_category(ws_path)
	else
		category = get_or_load_category(name)
	end

	if not category then
		return
	end

	category:delete()

	if is_default then
		loaded_workspace_categories[ws_path] = nil
		if workspace_category and is_default_category(workspace_category) then
			workspace_category = nil
		end
	else
		loaded_categories[name] = nil
		if workspace_category == name then
			workspace_category = nil
		end
	end

	local ws_map_changed = false
	for path, cat_name in pairs(ws_categories_map) do
		if is_default then
			if is_default_category(cat_name) and path == ws_path then
				ws_categories_map[path] = nil
				ws_map_changed = true
			end
		else
			if cat_name == name then
				ws_categories_map[path] = nil
				ws_map_changed = true
			end
		end
	end

	for bufnr, cat_name in pairs(buffer_categories) do
		if is_default then
			if is_default_category(cat_name) then
				buffer_categories[bufnr] = nil
			end
		else
			if cat_name == name then
				buffer_categories[bufnr] = nil
			end
		end
	end

	local file_map_changed = false
	for path, cat_name in pairs(file_categories_map) do
		if is_default then
			if is_default_category(cat_name) then
				file_categories_map[path] = nil
				file_map_changed = true
			end
		else
			if cat_name == name then
				file_categories_map[path] = nil
				file_map_changed = true
			end
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
	local default_name = get_default_name()
	local list = { default_name }
	local seen = {
		[default_name] = true,
		["Default"] = true,
		["default"] = true,
	}

	local search_pattern = string.format(constants.db_path, "*")
	local files = vim.fn.glob(search_pattern, false, true)

	for _, file in ipairs(files) do
		local name = string.match(file, "([^/\\]+)%.json$")

		if name and name ~= "" and not seen[name] and not is_default_category(name) then
			table.insert(list, name)
			seen[name] = true
		end
	end

	for name, _ in pairs(loaded_categories) do
		if not seen[name] and not is_default_category(name) then
			table.insert(list, name)
			seen[name] = true
		end
	end

	return list
end

function CategoryManager.set_buffer_category(name)
	local bufnr = vim.api.nvim_get_current_buf()
	if is_default_category(name) then
		buffer_categories[bufnr] = get_default_name()
	else
		buffer_categories[bufnr] = name
	end
end

function CategoryManager.set_workspace_category(name)
	local ws_path = CategoryManager.get_workspace_path()
	local default_name = get_default_name()

	if is_default_category(name) then
		workspace_category = default_name
		ws_categories_map[ws_path] = default_name
	else
		workspace_category = name
		ws_categories_map[ws_path] = name
	end

	utils.save_json(constants.ws_map_path, ws_categories_map)
end

function CategoryManager.set_file_category(name)
	local filepath = utils.global_filepath(0)
	if filepath ~= "" and vim.fn.filereadable(filepath) == 1 then
		if is_default_category(name) then
			file_categories_map[filepath] = get_default_name()
		else
			file_categories_map[filepath] = name
		end
		utils.save_json(constants.file_map_path, file_categories_map)
	else
		vim.notify("File does not exists", vim.log.levels.WARN)
	end
end

function CategoryManager.get_current_category(bufnr)
	bufnr = (bufnr and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
	local filepath = utils.global_filepath(bufnr)
	local current_ws = CategoryManager.get_workspace_path()

	local name = nil

	if buffer_categories[bufnr] then
		name = buffer_categories[bufnr]
	elseif filepath ~= "" and file_categories_map[filepath] then
		name = file_categories_map[filepath]
	elseif ws_categories_map[current_ws] then
		name = ws_categories_map[current_ws]
	elseif workspace_category then
		name = workspace_category
	end

	if name and not is_default_category(name) then
		return get_or_load_category(name)
	end

	return CategoryManager.get_workspace_default_category(current_ws)
end

return CategoryManager
