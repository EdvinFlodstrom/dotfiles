local wezterm = require 'wezterm'

return {
    -- Font settings
    font_size = 16.0,
    font = wezterm.font_with_fallback({
        {family="JetBrains Mono", weight="Regular", italic=false},
        {family="JetBrains Mono", weight="Bold", italic=false},
        {family="JetBrains Mono", weight="Regular", italic=true},
        {family="JetBrains Mono", weight="Bold", italic=true},
    }),

    -- Window settings
    window_background_opacity = 0.975,

    window_padding = {
        left = 5,
	right = 5,
	top = 5,
	bottom = 5,
    },

    -- Color scheme
    colors = {
        cursor_bg = "#a1a4b6",
	cursor_fg = "#020202",
	cursor_border = "#a1a4b6",

	foreground = "#deeaf4",
	background = "#191c1f",

        ansi = {
	    "#1e1e1e",
	    "#d16969",
	    "#b5cea8",
	    "#d7ba7d",
	    "#1f87cf",
	    "#c792ea",
	    "#86d0f6",
	    "#d4d4d4",
	},
	brights = {
	    "#546e7a",
	    "#f44747",
	    "#c3e88d",
	    "#ffcb6d",
	    "#0000ff",
	    "#c586c0",
	    "#92dfff",
	    "#deeeee",
	},
	indexed = {
	    [16] = "#1a1a1a",
	    [17] = "#8a4b48",
	    [18] = "#6f8b68",
	    [19] = "#a38658",
	    [20] = "#3a6a8e",
	    [21] = "#855a85",
	    [22] = "#6a9fb5",
	    [23] = "#a0a0a0",
	},
    },

    -- Enable Wayland support
    enable_wayland = true,
}
