local C = {}

local config = require("hover-notes.config")

function C.setup()
	C.db_path = config.options.notesDir .. "/categories/%s.json"
	C.file_map_path = config.options.notesDir .. "/file_categories.json"
	C.ws_map_path = config.options.notesDir .. "/ws_categories.json"
end

return C
