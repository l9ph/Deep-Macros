; Deep-Macros UI — tema global (estilo app nativa oscura)
class DM_Theme {
    static Current := {
        Name: "DeepDark",
        Bg: 0x0c0c10,
        Surface: 0x14141c,
        SurfaceAlt: 0x1c1c26,
        Border: 0x2a2a38,
        Accent: 0x3d7eff,
        AccentHover: 0x5b94ff,
        Success: 0x22c55e,
        Warning: 0xf59e0b,
        Danger: 0xef4444,
        Text: 0xeeeeee,
        TextMuted: 0x8b8b9e,
        FontUI: "Segoe UI",
        FontMono: "Cascadia Mono",
        Radius: 0,
        Pad: 14,
        HeaderH: 56,
        FooterH: 52,
        ControlH: 32
    }

    static Font(color := "", size := 10, bold := false, face := "") {
        t := DM_Theme.Current
        c := color != "" ? color : t.Text
        f := face != "" ? face : t.FontUI
        weight := bold ? " bold" : ""
        return "s" size " c" DM_Theme.ToFontColor(c) " " f weight
    }

    static ToFontColor(rgb) {
        hex := Format("{:06X}", rgb & 0xFFFFFF)
        return SubStr(hex, 1, 2) . SubStr(hex, 3, 2) . SubStr(hex, 5, 2)
    }

    static ApplyGui(gui, surface := false) {
        t := DM_Theme.Current
        gui.BackColor := surface ? t.Surface : t.Bg
    }
}
