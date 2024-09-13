local wezterm = require('wezterm')
local config = wezterm.config_builder()

local font_features = {
    'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06',
    'ss07', 'ss08'
}

local font = {
    family = "Monaspace Neon",
    weight = "DemiBold",
    harfbuzz_features=font_features,
}

wezterm.on("gui-startup", function()
    local _, _, window = wezterm.mux.spawn_window({})
    local screen = wezterm.gui.screens().active
    local win = window:gui_window()
    win:set_inner_size(screen.width / 2, screen.height)
    win:set_position(screen.width / 2, 0)
end)

config.adjust_window_size_when_changing_font_size = false
config.color_scheme = 'Catppuccin Macchiato'
config.command_palette_font_size = 12
config.font = wezterm.font_with_fallback({
    font,
    { family = "Symbols Nerd Font Mono", weight = "Bold", scale = 0.9 },
})
config.font_rules = {
    {
        intensity = 'Normal',
        italic = true,
        font = wezterm.font({
            family="Monaspace Neon",
            weight="Medium",
            stretch="Normal",
            style="Italic",
            harfbuzz_features=font_features,
        })
    },
    {
        intensity = 'Bold',
        italic = false,
        font = wezterm.font({
            family="Monaspace Neon",
            weight="Black",
            stretch="Normal",
            style="Normal",
            harfbuzz_features=font_features,
        })
    }
}
config.font_size = 11.5
config.hide_mouse_cursor_when_typing = false
config.hide_tab_bar_if_only_one_tab = true
config.keys = {
    {
        key = 'P',
        mods = 'SHIFT|CTRL',
        action = wezterm.action.SendString('\x01p')
    },
    {
        key = 'N',
        mods = 'SHIFT|CTRL',
        action = wezterm.action.SendString('\x01n')
    },
    {
        key = 'n',
        mods = 'CTRL|OPT',
        action = wezterm.action.SpawnWindow
    },
    {
        key = 'K',
        mods = 'SHIFT|CTRL',
        action = wezterm.action.SendString('\x01)')
    },
    {
        key = 'J',
        mods = 'SHIFT|CTRL',
        action = wezterm.action.SendString('\x01(')
    },
    {
        key = 'w',
        mods = 'CMD',
        action = wezterm.action.CloseCurrentTab({ confirm = false }),
    },
    {
        key = 'LeftArrow',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01H'),
    },
    {
        key = 'RightArrow',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01L'),
    },
    {
        key = 'UpArrow',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01K'),
    },
    {
        key = 'DownArrow',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01J'),
    },
    {
        key = 'j',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01j'),
    },
    {
        key = 'k',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01k'),
    },
    {
        key = 'l',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01l'),
    },
    {
        key = 'h',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01h'),
    },
    {
        key = '|',
        mods = 'OPT|SHIFT',
        action = wezterm.action.SendString('\x01|'),
    },
    {
        key = '-',
        mods = 'OPT',
        action = wezterm.action.SendString('\x01-'),
    },
    {
        key = 'Space',
        mods = 'CTRL',
        action = wezterm.action.ActivateCommandPalette
    },
    {
        key = 'Space',
        mods = 'OPT',
        action = wezterm.action.DisableDefaultAssignment
    },
}
config.window_background_opacity = 1
config.window_close_confirmation = 'NeverPrompt'
config.window_decorations = 'RESIZE'
config.window_frame = {
    font = wezterm.font(font),
    font_size = 10,
    active_titlebar_bg = '#35384b',
}
config.window_padding = {
    left = 4,
    right = 4,
    top = 0,
    bottom = 0,
}

return config
