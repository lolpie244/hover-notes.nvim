local C = {}

local config = require("hover-notes.config")

function C.setup()
	C.categories_dir = config.options.notesDir .. "/categories"
	C.workspaces_dir = config.options.notesDir .. "/workspaces"
	C.db_path = C.categories_dir .. "/%s.json"
	C.ws_db_path = C.workspaces_dir .. "/%s.json"
	C.file_map_path = config.options.notesDir .. "/file_categories.json"
	C.ws_map_path = config.options.notesDir .. "/ws_categories.json"
end

return C
