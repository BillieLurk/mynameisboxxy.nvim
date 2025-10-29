local M = {}

-- ╭─────────╮
-- │         │
-- │ DEFAULT │
-- │         │
-- ╰─────────╯
M.opts = {
	border = {
		corners = { tl = "╭", tr = "╮", bl = "╰", br = "╯" },
		horizontal = "─",
		vertical = "│",
		padding = { 1, 1 },
	},
}

function M.setup(user_opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, user_opts or {})
end

---@return integer, integer, string[]
local function get_visual_selection()
	local s = vim.fn.getpos("'<")[2]
	local e = vim.fn.getpos("'>")[2]
	local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
	return s, e, lines
end

---@param lines string[]
---@return number
local function longestLine(lines)
	local m = 0
	for _, line in ipairs(lines) do
		local w = vim.fn.strdisplaywidth(line)
		if w > m then
			m = w
		end
	end
	return m
end

-- ╭──────────────────────╮
-- │                      │
-- │ PARAMETERIZED BORDER │
-- │                      │
-- ╰──────────────────────╯
---@param lines string[]
---@param opts table
---@return string[]
local function add_border_custom(lines, opts)
	local border = opts.border or M.opts.border

	local tl = border.corners.tl or border.corner or "╭"
	local tr = border.corners.tr or border.corner or tl
	local bl = border.corners.bl or border.corner or tl
	local br = border.corners.br or border.corner or tl
	local h = border.horizontal or "─"
	local v = border.vertical or "│"
	local padding = border.padding or { 1, 1 }

	local px, py = padding[1] or 0, padding[2] or 0
	local max_len = longestLine(lines)
	local b_width = max_len + px * 2 + 2
	local inner_w = b_width - 2

	local top_border = tl .. string.rep(h, inner_w) .. tr
	local bottom_border = bl .. string.rep(h, inner_w) .. br
	local empty_border = v .. string.rep(" ", inner_w) .. v

	local out = {}
	table.insert(out, top_border)

	for _ = 1, py do
		table.insert(out, empty_border)
	end

	for _, line in ipairs(lines) do
		local line_w = vim.fn.strdisplaywidth(line)
		local right_pad = px + (max_len - line_w)
		local row = table.concat({
			v,
			string.rep(" ", px),
			line,
			string.rep(" ", right_pad),
			v,
		})
		table.insert(out, row)
	end

	for _ = 1, py do
		table.insert(out, empty_border)
	end
	table.insert(out, bottom_border)
	return out
end

local function replace_text()
	local s, e, lines = get_visual_selection()
	local bordered = add_border_custom(lines, M.opts)
	vim.api.nvim_buf_set_lines(0, s - 1, e, false, bordered)
end

function M.run()
	replace_text()
end

M.run()
return M
