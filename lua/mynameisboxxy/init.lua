local M = {}

M.opts = {
	border = {
		corners = { tl = "╭", tr = "╮", bl = "╰", br = "╯" },
		horizontal = "─",
		vertical = "│",
		padding = { 1, 1 },
	},
	styles = {},
}

-- reselect last visual and return normalized lines
local function get_visual_selection()
	-- refresh visual marks (safe in normal)
	pcall(vim.cmd, "normal! gv")

	local s = vim.fn.getpos("'<")[2]
	local e = vim.fn.getpos("'>")[2]

	-- normalize
	if s > e then
		s, e = e, s
	end

	local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
	return s, e, lines
end

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

-- expand tabs to spaces so box alignment is correct
local function expand_tabs(line, start_col, ts)
	local out, col = {}, start_col
	local n = vim.fn.strchars(line)
	for i = 0, n - 1 do
		local ch = vim.fn.strcharpart(line, i, 1)
		if ch == "\t" then
			local spaces = ts - ((col - 1) % ts)
			out[#out + 1] = string.rep(" ", spaces)
			col = col + spaces
		else
			out[#out + 1] = ch
			col = col + vim.fn.strdisplaywidth(ch)
		end
	end
	return table.concat(out)
end

local function add_border_custom(lines, tl, tr, bl, br, h, v, padding)
	local px = padding and padding[1] or 0
	local py = padding and padding[2] or 0
	local ts = vim.bo.tabstop or 4

	if tl and (not tr and not bl and not br) then
		tr, bl, br = tl, tl, tl
	end

	-- content starts after: left border (1) + left padding (px)
	local content_start_col = 1 + px

	-- expand all lines for correct measuring
	local expanded = {}
	for i, line in ipairs(lines) do
		expanded[i] = expand_tabs(line, content_start_col, ts)
	end

	-- now find longest expanded line
	local max_len = longestLine(expanded)
	local b_width = max_len + px * 2 + 2
	local inner_w = b_width - 2

	local top_border = tl .. string.rep(h, inner_w) .. tr
	local bottom_border = bl .. string.rep(h, inner_w) .. br
	local empty_border = v .. string.rep(" ", inner_w) .. v

	local out = { top_border }

	-- top padding
	for _ = 1, py do
		out[#out + 1] = empty_border
	end

	-- content
	for _, line in ipairs(expanded) do
		local line_w = vim.fn.strdisplaywidth(line)
		local right_pad = px + (max_len - line_w)
		out[#out + 1] = table.concat({
			v,
			string.rep(" ", px),
			line,
			string.rep(" ", right_pad),
			v,
		})
	end

	-- bottom padding
	for _ = 1, py do
		out[#out + 1] = empty_border
	end

	out[#out + 1] = bottom_border
	return out
end

function M.setup(user_opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, user_opts or {})
end

-- base runner
function M.run(override)
	local s, e, lines = get_visual_selection()
	local opts = vim.tbl_deep_extend("force", M.opts, override or {})

	-- pick border from opts
	local b = opts.border or {}
	local c = b.corners or {}
	local tl = c.tl or b.corner
	local tr = c.tr
	local bl = c.bl
	local br = c.br
	local horizontal = b.horizontal
	local vertical = b.vertical
	local padding = b.padding or { 1, 1 }

	local bordered = add_border_custom(lines, tl, tr, bl, br, horizontal, vertical, padding)

	-- replace selection
	vim.api.nvim_buf_set_lines(0, s - 1, e, false, bordered)
end

-- run a named style from opts.styles
function M.run_style(name)
	local style = (M.opts.styles or {})[name]
	if not style then
		return M.run()
	end
	return M.run(style)
end

return M
