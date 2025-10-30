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

-- widest display width starting at column `startcol` (handles tabs/wide chars)
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

-- build bordered block
local function add_border(lines, border)
	local c = (border.corners or {})
	local tl = c.tl or border.corner
	local tr = c.tr
	local bl = c.bl
	local br = c.br
	local h = border.horizontal or "-"
	local v = border.vertical or "|"
	local px = (border.padding and border.padding[1]) or 0
	local py = (border.padding and border.padding[2]) or 0

	-- single-corner shorthand
	if tl and (not tr and not bl and not br) then
		tr, bl, br = tl, tl, tl
	end

	-- width calc must start after left border + left padding for correct tab expansion
	local startcol = 1 + px
	local max_len = longest_line(lines, startcol)

	local inner_w = max_len + px * 2
	local top_border = (tl or "+") .. string.rep(h, inner_w) .. (tr or "+")
	local bottom_border = (bl or "+") .. string.rep(h, inner_w) .. (br or "+")
	local empty_border = v .. string.rep(" ", inner_w) .. v

	local out = { top_border }
	for _ = 1, py do
		out[#out + 1] = empty_border
	end

	for _, line in ipairs(lines) do
		local line_w = vim.fn.strdisplaywidth(line, startcol)
		local right_px = px + (max_len - line_w)
		out[#out + 1] = table.concat({
			v,
			string.rep(" ", px),
			line,
			string.rep(" ", right_px),
			v,
		})
	end

	for _ = 1, py do
		out[#out + 1] = empty_border
	end
	out[#out + 1] = bottom_border
	return out
end

-- operate on a concrete range [s, e] (1-based inclusive)
function M.run_range(s, e, override)
	if s > e then
		s, e = e, s
	end
	local opts = vim.tbl_deep_extend("force", M.opts, override or {})
	local border = opts.border or {}

	local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
	local bordered = add_border(lines, border)
	vim.api.nvim_buf_set_lines(0, s - 1, e, false, bordered)
end

local function define_user_command()
	if vim.g._boxxy_cmd_defined then
		return
	end
	vim.g._boxxy_cmd_defined = true

	vim.api.nvim_create_user_command("BoxxyBorder", function(cmd)
		local s, e = cmd.line1, cmd.line2
		local style_name = cmd.args ~= "" and cmd.args or "default"
		local style_opts = (M.opts.styles or {})[style_name]

		if style_opts == nil and style_name ~= "default" then
			vim.notify(("BoxxyBorder: unknown style '%s'"):format(style_name), vim.log.levels.WARN)
			style_opts = {}
		end

		M.run_range(s, e, style_opts or {})
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
