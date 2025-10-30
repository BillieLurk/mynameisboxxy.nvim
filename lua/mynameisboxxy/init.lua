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

local function get_visual_selection()
	local s = vim.fn.getpos("'<")[2]
	local e = vim.fn.getpos("'>")[2]
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

local function add_border_custom(lines, tl, tr, bl, br, h, v, padding)
	local px = padding and padding[1] or 0
	local py = padding and padding[2] or 0
	if tl and (not tr and not bl and not br) then
		tr, bl, br = tl, tl, tl
	end

	local max_len = longestLine(lines)
	local b_width = max_len + px * 2 + 2
	local inner_w = b_width - 2
	local top_border = tl .. string.rep(h, inner_w) .. tr
	local bottom_border = bl .. string.rep(h, inner_w) .. br
	local empty_border = v .. string.rep(" ", inner_w) .. v
	local out = { top_border }

	for _ = 1, py do
		out[#out + 1] = empty_border
	end
	for _, line in ipairs(lines) do
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
	vim.api.nvim_buf_set_lines(0, s - 1, e, false, bordered)
end

-- run a named style from opts.styles
function M.run_style(name)
	local style = (M.opts.styles or {})[name]
	if not style then
		-- fallback to default
		return M.run()
	end
	return M.run(style)
end

return M
