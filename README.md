# git-conflict.nvim

Visualise and resolve Git conflict markers in Neovim. Supports ordinary merge
conflicts and diff3 conflicts with a base section.

## Requirements

- Neovim 0.10+
- Git (for listing conflicted files)

## Installation

```lua
-- lazy.nvim
{ "seblyng/git-conflict.nvim" }
```

The plugin starts automatically. Call `setup()` only to customise mappings:

```lua
require("git-conflict").setup({
    default_mappings = {
        ours = "co",
        theirs = "ct",
        none = "c0",
        both = "cb",
        next = "]x",
        prev = "[x",
    },
})
```

Set `default_mappings = false` to use only your own mappings.

## Resolving conflicts

Default mappings are buffer-local and active while the buffer contains conflicts:

| Mapping | Action |
| --- | --- |
| `co` | Keep ours (current changes) |
| `ct` | Keep theirs (incoming changes) |
| `cb` | Keep ours followed by theirs |
| `c0` | Remove both sides |
| `]x` | Jump to the next conflict, wrapping at the end |
| `[x` | Jump to the previous conflict, wrapping at the beginning |

Resolution mappings work on the conflict under the cursor in normal mode, or
on conflicts fully enclosed by a visual selection.

The following `<Plug>` mappings are available for custom bindings:

```lua
vim.keymap.set({ "n", "v" }, "co", "<Plug>(git-conflict-ours)")
vim.keymap.set({ "n", "v" }, "ct", "<Plug>(git-conflict-theirs)")
vim.keymap.set({ "n", "v" }, "cb", "<Plug>(git-conflict-both)")
vim.keymap.set({ "n", "v" }, "c0", "<Plug>(git-conflict-none)")
vim.keymap.set({ "n", "v" }, "ca", "<Plug>(git-conflict-base)")
vim.keymap.set("n", "]x", "<Plug>(git-conflict-next-conflict)")
vim.keymap.set("n", "[x", "<Plug>(git-conflict-prev-conflict)")
```

Choosing base requires a diff3 conflict containing a `|||||||` section.

## Listing conflicts

`:GitConflict qf` opens a quickfix list with one entry per conflict in files Git
reports as unmerged in the current buffer's repository.

`require("git-conflict").conflicts_to_qf_items()` returns those quickfix entries
without opening the list.

## Highlights

Customise these highlight groups using `vim.api.nvim_set_hl()`:

- `GitConflictCurrent` (defaults to `DiffText`)
- `GitConflictIncoming` (defaults to `DiffAdd`)
- `GitConflictAncestor`
- `GitConflictCurrentLabel`
- `GitConflictIncomingLabel`
- `GitConflictAncestorLabel`
