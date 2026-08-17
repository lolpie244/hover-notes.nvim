local utils = {}

function utils.global_filepath(bufnr)
	bufnr = bufnr or 0
	return vim.api.nvim_buf_call(bufnr, function()
		return vim.fn.expand("%:p")
	end)
end

function utils.load_json(path)
	if vim.fn.filereadable(path) == 0 then
		return nil
	end

	local content = table.concat(vim.fn.readfile(path), "")

	if content == "" then
		return nil
	end

	local ok, decoded = pcall(vim.json.decode, content)

	if ok then
		return decoded
	end

	return nil
end

function utils.save_json(path, data)
	local ok, encoded = pcall(vim.json.encode, data)

	if ok then
		vim.fn.writefile({ encoded }, path)
	end
end

function utils.merge_arrays(...)
	local mergedArray = {}
	local startIndex = 1

	for _, array in ipairs({ ... }) do
		local endIndex = startIndex + #array - 1
		table.move(array, 1, #array, startIndex, mergedArray)
		startIndex = endIndex + 1
	end

	return mergedArray
end

return utils
