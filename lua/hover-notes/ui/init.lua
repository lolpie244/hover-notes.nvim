local UI = {}
local config = require("hover-notes.config")

local FloatEditor = require("hover-notes.ui.float_editor")

function UI.open_float_editor(title, fields, on_save)
	FloatEditor:new(title, fields, on_save)
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
	vim.lsp.util.open_floating_preview(lines, "markdown", {
		border = opts.border,
        title = " " .. title .. " ",
	})
end

return UI
