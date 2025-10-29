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
require("mynameisboxxy").setup({
  border = {
    corners = { tl = "╭", tr = "╮", bl = "╰", br = "╯" },
    horizontal = "─",
    vertical = "│",
    padding = { 1, 1 },
  },
})
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
