-- System fallback shell. ~/.config/mantle/shell.lua takes precedence through
-- the niri startup command.

fonts {
    "JetBrains Mono",
    "Noto Sans",
}

return {
    panel {
        id = "bar",
        layer = "top",
        anchor = { top = true, left = true, right = true },
        exclusive_zone = true,
        width = "fill",
        height = 34,
        background = "#1e1e2e80",
        child = row {
            width = "fill",
            height = "fill",
            align_h = "end",
            padding = { left = 12, right = 12 },
            children = {
                text {
                    content = mantle.system:map(function(s)
                        return os.date("%H:%M", s and s.time)
                    end),
                    align_v = "center",
                    font_size = 13,
                    foreground = "#cdd6f4ff",
                },
            },
        },
    },
}
