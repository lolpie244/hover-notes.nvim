local NotesDB = {}
NotesDB.__index = NotesDB

local utils = require("hover-notes.utils")
local constants = require("hover-notes.constants")

function NotesDB:new(path)
	local instance = setmetatable({}, NotesDB)

	instance.filename = path
	instance.data = utils.load_json(path) or {}
	instance.data.__meta__ = instance.data.__meta__ or {}

	return instance
end

local function levenshtein_distance(str1, str2, max_dist)
	local len1, len2 = #str1, #str2

	if math.abs(len1 - len2) > max_dist then
		return math.huge
	end

	local prev_row = {}
	local curr_row = {}

	for j = 0, len2 do
		prev_row[j] = j
	end

	for i = 1, len1 do
		curr_row[0] = i
		local min_in_row = i

		for j = 1, len2 do
			local cost = (str1:sub(i, i) == str2:sub(j, j) and 0 or 1)
			curr_row[j] = math.min(
				prev_row[j] + 1, -- deletion
				curr_row[j - 1] + 1, -- insertion
				prev_row[j - 1] + cost -- substitution
			)

			if curr_row[j] < min_in_row then
				min_in_row = curr_row[j]
			end
		end

		if min_in_row > max_dist then
			return math.huge
		end

		for j = 0, len2 do
			prev_row[j] = curr_row[j]
		end
	end

	return curr_row[len2]
end

function NotesDB:get(word)
	if word == "__meta__" then
		return nil
	end

	if self.data[word] then
		return self.data[word], word
	end

	local best_match_key = nil
	local lowest_distance = math.huge
	local target_word = word:lower()

    local max_allowed_distance = math.max(0, math.ceil(#word / 2) - 1)

	for key, _ in pairs(self.data) do
		if key ~= "__meta__" then
			local dist = levenshtein_distance(target_word, key:lower(), max_allowed_distance)

			if dist < lowest_distance then
				lowest_distance = dist
				best_match_key = key
			end
		end
	end

	if best_match_key and lowest_distance <= max_allowed_distance then
		return self.data[best_match_key], best_match_key
	end

	return nil, word
end

function NotesDB:set(word, note_content)
	self.data[word] = note_content
	return self:save()
end

function NotesDB:get_meta(key)
	return self.data.__meta__[key]
end

function NotesDB:set_meta(key, value)
	self.data.__meta__[key] = value
	return self:save()
end

function NotesDB:save()
	local ok, encoded = pcall(vim.json.encode, self.data)
	if not ok then
		return false
	end

	local dir = vim.fs.dirname(self.filename)

	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end

	vim.fn.writefile({ encoded }, self.filename)
	return true
end

function NotesDB:delete()
	vim.fn.delete(self.filename)
	self.filename = nil
	self.data = nil
end

return NotesDB
