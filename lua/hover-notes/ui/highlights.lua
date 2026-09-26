local Highlight = {}
Highlight.__index = Highlight

local config = require("hover-notes.config")

local win_bounds = {}
local highlight_group = "HoverNoteWord"
local ns_id = vim.api.nvim_create_namespace("hover_notes_hl")

local function exact_word_match(bufnr, row, win_bound, words_dict)
	local matches = {}

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	local limit = math.min(#line, win_bound.right)

	local start_idx = nil
	local end_idx = win_bound.left + 1
	while end_idx <= limit do
		start_idx, end_idx = string.find(line, "[%w_-]+", end_idx)
		if not start_idx or start_idx > limit then
			break
		end

		local word = string.sub(line, start_idx, end_idx):lower()

		if words_dict[word] and word ~= "__meta__" then
			table.insert(matches, { start_idx - 1, end_idx })
		end
		end_idx = end_idx + 1
	end

	return matches
end

local function substring_match(bufnr, row, win_bound, regex)
	local matches = {}

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if not line or win_bound.left >= #line then
		return matches
	end

	local limit = math.min(#line, win_bound.right)

	local start_idx = 0
	local end_idx = win_bound.left

	while end_idx < limit do
		local rel_start, rel_end = regex:match_line(bufnr, row, end_idx, limit)

		if not rel_start or end_idx + rel_start > limit then
			break
		end

		start_idx = end_idx + rel_start
		end_idx = end_idx + rel_end

		table.insert(matches, { start_idx, end_idx })

		if start_idx == end_idx then
			end_idx = end_idx + 1
		end
	end

	return matches
end

function Highlight.setup(cat_manager)
	vim.api.nvim_set_hl(0, highlight_group, config.options.highlight.style)

	vim.api.nvim_set_decoration_provider(ns_id, {
		on_start = function()
			win_bounds = {}
			return true
		end,
		on_win = function(_, winnr, _, _, _)
			if not cat_manager.get_current_category() or not cat_manager.get_current_category().db.data then
				return false
			end

			local left = 0
			local right = math.huge

			if not vim.wo[winnr].wrap then
				if winnr == vim.api.nvim_get_current_win() then
					left = vim.fn.winsaveview().leftcol
				end
				right = left + vim.api.nvim_win_get_width(winnr)
			end

			win_bounds[winnr] = {
				left = left,
				right = right,
			}

			return true
		end,

		on_line = function(_, winnr, bufnr, row)
			local cat = cat_manager.get_current_category()

			local matches = {}

			if cat:regex() then
				matches = substring_match(bufnr, row, win_bounds[winnr], cat:regex())
			else
				matches = exact_word_match(bufnr, row, win_bounds[winnr], cat.db.data)
			end

			for _, match in ipairs(matches) do
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, match[1], {
					end_col = match[2],
					hl_group = highlight_group,
					ephemeral = true,
					priority = 200,
				})
			end
		end,
	})
end

return Highlight
