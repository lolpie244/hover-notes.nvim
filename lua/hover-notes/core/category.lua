local constants = require("hover-notes.constants")

local NotesDB = require("hover-notes.core.notes_db")

local Category = {}
Category.__index = Category

function Category:new(name)
	local instance = setmetatable({}, Category)
	instance.name = name
	instance.fields = {}

	local db_path = string.format(constants.db_path, name)
	instance.db = NotesDB:new(db_path)

    instance:set_format(instance.db:get_meta("format") or "")

	return instance
end

function Category:set_format(format)
    self.fields = {}
	self.format = format

    self.db:set_meta("format", format)

	for field in string.gmatch(format, "{(.-)}") do
		table.insert(self.fields, field)
	end
end

function Category:set_note(word, vars)
	return self.db:set(word, vars)
end

function Category:get_note(word)
	local vars, matched_word = self.db:get(word)

	if not vars then
		return nil, word
	end

	local result_string = string.gsub(self.format, "{(.-)}", function(key)
		return vars[key] or ""
	end)

	return result_string, matched_word
end

function Category:delete()
    self.db:delete()

    self.name = nil
	self.fields = nil
    self.format = nil
    self.db = nil
end

return Category
