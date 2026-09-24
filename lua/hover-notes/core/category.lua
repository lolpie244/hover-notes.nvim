local constants = require("hover-notes.constants")
local config = require("hover-notes.config")

local NotesDB = require("hover-notes.core.notes_db")

local Category = {}
Category.__index = Category

function Category:new(name)
	local instance = setmetatable({}, Category)
	instance.name = name
	instance.fields = {}
	instance.compiled_regex = nil
	instance.pattern_size = nil

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
	self.compiled_regex = nil
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
	self.compiled_regex = nil
end

function Category:regex()
	if self.compiled_regex == nil then
		local words = {}

		if self.db:words_len() > config.options.highlight.subsstr_match_size_limit then
			self.compiled_regex = false
			return nil
		end

		for key, _ in pairs(self.db.data) do
			table.insert(words, key)
		end

		if #words == 0 then
			return nil
		end

		table.sort(words, function(a, b)
			return #a > #b
		end)

		local pattern = "\\v\\c%(" .. table.concat(words, "|") .. ")"

		local ok, regex = pcall(vim.regex, pattern)
		if ok then
			self.compiled_regex = regex
		else
			self.compiled_regex = false
		end
	end

	if self.compiled_regex == false then
		return nil
	end

	return self.compiled_regex
end

return Category
