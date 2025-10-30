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

-- find display width of the widest line (handles tabs, wide chars)
local function longest_line(lines, startcol)
	local m = 0
	for _, line in ipairs(lines) do
		local w = vim.fn.strdisplaywidth(line, startcol or 0)
		if w > m then
			m = w
		end
	end
	return m
end

-- produce a bordered block of lines
local function add_border_custom(lines, tl, tr, bl, br, h, v, padding)
	local px = padding and padding[1] or 0
	local py = padding and padding[2] or 0

	if tl and (not tr and not bl and not br) then
		tr, bl, br = tl, tl, tl
	end

	-- start column after the left border + left padding
	local startcol = 1 + px

	-- compute widths with the correct starting column to account for tabs
	local max_len = longest_line(lines, startcol)

	local b_width = max_len + px * 2 + 2
	local inner_w = b_width - 2

	local top_border = (tl or "+") .. string.rep(h or "-", inner_w) .. (tr or "+")
	local bottom_border = (bl or "+") .. string.rep(h or "-", inner_w) .. (br or "+")
	local empty_border = (v or "|") .. string.rep(" ", inner_w) .. (v or "|")

	local out = { top_border }

	for _ = 1, py do
		out[#out + 1] = empty_border
	end

	for _, line in ipairs(lines) do
		-- width from the same start column so tab expansion matches actual layout
		local line_w = vim.fn.strdisplaywidth(line, startcol)
		local right_pad = px + (max_len - line_w)
		out[#out + 1] = table.concat({
			(v or "|"),
			string.rep(" ", px),
			line,
			string.rep(" ", right_pad),
			(v or "|"),
		})
	end

	for _ = 1, py do
		out[#out + 1] = empty_border
	end

	out[#out + 1] = bottom_border
	return out
end

-- core: operate on a concrete line range [s, e] (1-based, inclusive)
function M.run_range(s, e, override)
	if s > e then
		s, e = e, s
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

	local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
	local bordered = add_border_custom(lines, tl, tr, bl, br, horizontal, vertical, padding)

	-- replace selection with bordered block
	vim.api.nvim_buf_set_lines(0, s - 1, e, false, bordered)
end

-- programmatic: use visual marks if you really want (not used by the keymaps below)
function M.run(override)
	local s = vim.fn.getpos("'<")[2]
	local e = vim.fn.getpos("'>")[2]
	if s == 0 or e == 0 then
		local cur = vim.api.nvim_win_get_cursor(0)[1]
		s, e = cur, cur
	end
	if s > e then
		s, e = e, s
	end
	return M.run_range(s, e, override)
end

-- convenience: run by style name found in opts.styles
function M.run_style(name)
	local style_opts = (M.opts.styles or {})[name]
	if not style_opts then
		return M.run() -- fallback to default
	end
	return M.run(style_opts)
end

-- create the range-aware :BoxxyBorder [style] command
local function define_user_command()
	-- avoid redefining across reloads
	if vim.g._boxxy_cmd_defined then
		return
	end
	vim.g._boxxy_cmd_defined = true

	vim.api.nvim_create_user_command("BoxxyBorder", function(cmd)
		local s, e = cmd.line1, cmd.line2
		local style_name = cmd.args ~= "" and cmd.args or "default"
		local style_opts = (M.opts.styles or {})[style_name] or (style_name == "default" and {} or nil)

		if style_opts == nil then
			vim.notify(("BoxxyBorder: unknown style '%s'"):format(style_name), vim.log.levels.WARN)
			style_opts = {}
		end

		M.run_range(s, e, style_opts)
	end, {
		range = true,
		nargs = "?",
		desc = "Add a box border around the given range",
		complete = function()
			return vim.tbl_keys(M.opts.styles or {})
		end,
	})
end

function M.setup(user_opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, user_opts or {})
	define_user_command()
end

return M
