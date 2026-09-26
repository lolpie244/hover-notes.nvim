<p align="center">
  <h1 align="center">hover-notes.nvim</h1>
</p>

<p align="center">
	Custom hover notes with categories support
</p>


https://github.com/user-attachments/assets/97233790-a8df-4e90-ac1c-fe534aa04561


<details>
<summary>Table of Contents</summary>
	<li><a href="#description">Description</a></li>
	<li><a href="#installation">Installation</a></li>
    <li><a href="#configuration">Configuration</a></li>
	<li><a href="#commands">Commands</a></li>
</details>

## Description
The main goal of this plugin is to add the ability to attach notes to words and view them in a floating window

The same note is displayed for every occurrence of this word, not only in specific line/file/buffer

Features:
- Notes can be grouped by categories with the same formatting
- A default category is maintained for each workspace individually
- A category can be set for a workspace, a buffer, or an individual file
- Retrieves the closest matching word (up to a difference of half the word's length)
- Highlight with support for big files & big dictionaries
- Quiz mode to test your knowledge


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
    highlight = {
		enable = true,
		-- if length of words in dictionary is longer than subsstr_match_size_limit - use exact word match instead of substring
		subsstr_match_size_limit = 1000,
		style = { underline = true, sp = vim.api.nvim_get_hl(0, { name = "String", link = false }).fg, bold = true, default = true },
	},

})
```
- - -
## Commands
| Command                       | Description                                                     |
| ----------------------------- | --------------------------------------------------------------- |
| `HNShow {word}`               | Show the note for the word*                                     |
| `HNEdit {word}`               | Add/edit the note for the word*                                 |
| `HNDeleteNote {word}`         | Delete the note for the word*                                   |
| `HNQuiz {word}`               | Start Quiz mode for the word*                                   |
| `HNCreateCategory {name}`     | Create new notes category                                       |
| `HNDeleteCategory {name}`     | Delete existing category with all notes                         |
| `HNGetCategory`               | Get category used by this buffer                                |
| `HNSetWorkspace {name}`       | Set notes category for the workspace                            |
| `HNSetBuffer {name}`          | Set notes category for the buffer                               |
| `HNSetFile {name}`            | Set notes category for the file                                 |

\*All commands that target a word (`HNShow, HNEdit...`) will automatically prioritize:
1) Word provided as an argument: `:HNShow lorem`
2) A visual selection
3) The word under cursor


## TODO
- [x] Add Quiz mode
- [x] Add confirmation on removal
- [x] Visual highlight of the words with notes
