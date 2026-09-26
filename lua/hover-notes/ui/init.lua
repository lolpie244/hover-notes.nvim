local UI = {}
local config = require("hover-notes.config")

local FloatWindow = require("hover-notes.ui.float_window")
local FloatEditor = require("hover-notes.ui.float_editor")
local FloatDiff = require("hover-notes.ui.float_diff")
local Highlight = require("hover-notes.ui.highlights")

function UI.open_float_editor(title, fields, on_save)
	FloatEditor:new(title, fields, on_save)
end

function UI.open_float_diff(title, fields, attempt, correct)
    local is_perfect = true

	for _, field in ipairs(fields) do
		if vim.trim(attempt[field.name] or "") ~= vim.trim(correct[field.name] or "") then
			is_perfect = false
			break
		end
	end

    if is_perfect then
        local perfect_fields = {}
        for _, field in ipairs(fields) do
            table.insert(perfect_fields, {
                name = field.name,
                value = correct[field.name] or "",
            })
        end

        local window = FloatWindow:new("Perfect match", perfect_fields)
        window:set_modifiable(false)
        return
    end

	FloatDiff:new(title, fields, attempt, correct)
end

function UI.select(prompt, categories, on_select)
	if not categories or #categories == 0 then
		vim.notify("No categories found. Create one first!", vim.log.levels.WARN)
		return
	end

	vim.ui.select(categories, { prompt = prompt }, function(item)
		if item then
			on_select(item)
		end
	end)
end

function UI.show_hover(title, text)
	local opts = config.options.ui.float

	local lines = vim.split(text, "\n", { plain = true })

	vim.schedule(function()
		vim.lsp.util.open_floating_preview(lines, "markdown", {
			border = opts.border,
			title = " " .. title .. " ",
		})
	end)
end

function UI.setup_highlight(manager)
	Highlight.setup(manager)
end

return UI
