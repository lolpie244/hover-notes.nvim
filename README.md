<p align="center">
  <h1 align="center">hover-notes.nvim</h1>
</p>

<p align="center">
	Custom hover notes with categories support
</p>


https://github.com/user-attachments/assets/97233790-a8df-4e90-ac1c-fe534aa04561


<details>
<summary>Table of Contents</summary>
	<li><a href="#installation">Installation</a></li>
    <li><a href="#configuration">Configuration</a></li>
	<li><a href="#commands">Commands</a></li>
</details>


## Installation
Install the plugin with your favourite package manager:
<details>
  <summary>lazy.nvim</summary>

```lua
{
  "lolpie244/hover-notes.nvim",
}
```

</details>

<details>
  <summary>Packer</summary>

```lua
require('packer').startup(function()
    use {
      "lolpie244/hover-notes.nvim",
    }
end)
```
</details>

## Configuration
``` lua
require("hover-notes").setup({
	notesDir = vim.fn.stdpath("data") .. "/hover-notes", -- the root directory where all notes are stored
	defaultCategory = { -- the default note category
		name = "Default",
		format = "{text}",
	},
	ui = { -- style of the float window
		float = {
			style = "minimal",
			border = "rounded",
		},
	},
})
```
- - -
## Commands

| Command                       | Description                              |
| ----------------------------- | ---------------------------------------- |
| `HNShow`                      | Show note for word under cursor          |
| `HNEdit`                      | Add/edit note for word under cursor      |
| `HNCreateCategory {name}`     | Create new notes category                |
| `HNDeleteCategory {name}`     | Delete existing category with all notes  |
| `HNSetWorkspace {name}`       | Set notes category for the workspace     |
| `HNSetBuffer {name}`          | Set notes category for the buffer        |
| `HNSetFile {name}`            | Set notes category for the file          |



## TODO
- [ ] Add Quiz mode
- [ ] Add confirmation on removal; move category to trash
- [ ] Visual highlight of the words with notes
