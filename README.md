# 📦 mynameisboxxy.nvim

_A playful yet powerful Neovim plugin for wrapping text selections in fancy customizable boxes._

---

## 🧠 Overview

**mynameisboxxy.nvim** lets you draw beautiful text boxes right inside Neovim — like an old-school TUI or a high-effort ASCII comment block.

It takes any visual selection and surrounds it with a border made of characters you choose — rounded, double-lined, solid, or something completely chaotic.

Perfect for **comment headers**, **markdown highlights**, or just **showing off some flair** in your config files.

---

## ⚙️ Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "billrosander/mynameisboxxy.nvim",
  config = function()
    require("mynameisboxxy").setup()
  end
}

```

## Configuration

```lua
return {
  "BillieLurk/mynameisboxxy.nvim",
  config = function()
    require("mynameisboxxy").setup({
      border = {
        corners    = { tl = "╭", tr = "╮", bl = "╰", br = "╯" },
        horizontal = "─",
        vertical   = "│",
        padding    = { 1, 1 },
      },
      styles = {
        -- uses the top-level border
        default = {},

        double = {
          border = {
            corners    = { tl = "╔", tr = "╗", bl = "╚", br = "╝" },
            horizontal = "═",
            vertical   = "║",
            padding    = { 1, 1 },
          },
        },

        ascii = {
          border = {
            corner     = "+",
            horizontal = "-",
            vertical   = "|",
            padding    = { 1, 0 },
          },
        },
      },
    })
  end,
  keys = {
    -- Range-aware command so first run always works in Visual mode
    { "<leader>bx", ":'<,'>BoxxyBorder default<CR>", mode = "v", desc = "Boxxy: rounded" },
    { "<leader>bd", ":'<,'>BoxxyBorder double<CR>",  mode = "v", desc = "Boxxy: double"   },
    { "<leader>ba", ":'<,'>BoxxyBorder ascii<CR>",   mode = "v", desc = "Boxxy: ascii"    },
  },
}
```

## Examples

```
╭───────────────────────────────╮
│ mynameisboxxy is very classy! │
╰───────────────────────────────╯

╔═══════════════════════════════╗
║ mynameisboxxy is feeling bold ║
╚═══════════════════════════════╝
```
