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

-- get current buffer line count (for clamping)
local function get_buf_line_count()
	return vim.api.nvim_buf_line_count(0)
end

-- get visual selection, robust
local function get_visual_selection()
	local mode = vim.fn.mode()

	-- if we're NOT in visual now, try to reselect the last visual
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		pcall(vim.cmd, "normal! gv")
	end

	local s = vim.fn.getpos("'<")[2]
	local e = vim.fn.getpos("'>")[2]

	-- if still nothing, bail
	if s == 0 or e == 0 then
		return nil, nil, nil
	end

	-- normalize
	if s > e then
		s, e = e, s
	end

	-- clamp to buffer line count
	local maxline = get_buf_line_count()
	if e > maxline then
		e = maxline
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

	local content_start_col = 1 + px

	local expanded = {}
	for i, line in ipairs(lines) do
		expanded[i] = expand_tabs(line, content_start_col, ts)
	end

	local max_len = longestLine(expanded)
	local b_width = max_len + px * 2 + 2
	local inner_w = b_width - 2

	local top_border = tl .. string.rep(h, inner_w) .. tr
	local bottom_border = bl .. string.rep(h, inner_w) .. br
	local empty_border = v .. string.rep(" ", inner_w) .. v

	local out = { top_border }

	for _ = 1, py do
		out[#out + 1] = empty_border
	end

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

	for _ = 1, py do
		out[#out + 1] = empty_border
	end

	out[#out + 1] = bottom_border
	return out
end

function M.setup(user_opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, user_opts or {})
end

function M.run(override)
	local s, e, lines = get_visual_selection()
	if not s or not e or not lines then
		return
	end

	local opts = vim.tbl_deep_extend("force", M.opts, override or {})
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

	-- write back (s,e are normalized and clamped)
	vim.api.nvim_buf_set_lines(0, s - 1, e, false, bordered)

	-- exit visual
	vim.cmd("normal! <Esc>")
end

function M.run_style(name)
	local style = (M.opts.styles or {})[name]
	if not style then
		return M.run()
	end
	return M.run(style)
end

return M
