class DM_Theme {
    static Current := {
        Name: "DeepDark",
        Bg: 0x0a0a0e,
        Surface: 0x12121a,
        SurfaceAlt: 0x1a1a24,
        CardBg: 0x16161f,
        CardBorder: 0x2e2e3d,
        RowBg: 0x1e1e28,
        InputBg: 0x22222e,
        Border: 0x2a2a38,
        Accent: 0x4f8cff,
        AccentHover: 0x6ba0ff,
        ToggleOn: 0x4f8cff,
        ToggleOff: 0x35354a,
        ToggleKnob: 0xf5f5fa,
        BtnPrimary: 0x4f8cff,
        BtnGhost: 0x22222e,
        BtnGhostHover: 0x2e2e3c,
        Success: 0x22c55e,
        Warning: 0xf59e0b,
        Danger: 0xef4444,
        Text: 0xf0f0f5,
        TextMuted: 0x9090a8,
        FontUI: "Segoe UI",
        FontMono: "Cascadia Mono",
        Radius: 0,
        FrameBorder: 1,
        FrameColor: 0x2a2a38,
        TitleBarH: 36,
        TitleBarSubH: 58,
        Pad: 16,
        HeaderH: 48,
        FooterH: 54,
        ControlH: 34,
        CornerRadius: 8
    }

    static Font(color := "", size := 10, bold := false) {
        t := DM_Theme.Current
        c := color != "" ? color : t.Text
        weight := bold ? " bold" : ""
        return "s" size " c" DM_Theme.ToFontColor(c) weight
    }

    static FontName(face := "") {
        t := DM_Theme.Current
        return face != "" ? face : t.FontUI
    }

    static ToFontColor(rgb) {
        hex := Format("{:06X}", rgb & 0xFFFFFF)
        return SubStr(hex, 1, 2) . SubStr(hex, 3, 2) . SubStr(hex, 5, 2)
    }

    static ApplyGui(gui, surface := false) {
        t := DM_Theme.Current
        gui.BackColor := surface ? t.Surface : t.Bg
    }

    static UseRayfield() {
        t := DM_Theme.Current
        t.Name := "Rayfield"
        t.Bg := 0x191919
        t.Surface := 0x222222
        t.SurfaceAlt := 0x232323
        t.Topbar := 0x222222
        t.CardBg := 0x232323
        t.CardBorder := 0x323232
        t.RowBg := 0x232323
        t.InputBg := 0x1e1e1e
        t.Border := 0x323232
        t.Accent := 0x328ADC
        t.AccentHover := 0x3AA0FF
        t.ToggleOn := 0x0092D6
        t.ToggleOff := 0x646464
        t.ToggleKnob := 0xF0F0F0
        t.ToggleStrokeOn := 0x00AAFF
        t.ToggleStrokeOff := 0x7D7D7D
        t.BtnPrimary := 0x328ADC
        t.BtnGhost := 0x232323
        t.BtnGhostHover := 0x282828
        t.TabBg := 0x2d2d2d
        t.TabBgSelected := 0xD4D4D4
        t.TabText := 0xA8A8A8
        t.TabTextSelected := 0x1a1a1a
        t.RowBg := 0x232323
        t.ToggleOff := 0x3a3a3a
        t.ToggleOn := 0x0092D6
        t.ToggleKnob := 0xFFFFFF
        t.SliderBg := 0x328ADC
        t.SliderFill := 0x3AA3FF
        t.Text := 0xF0F0F0
        t.TextMuted := 0xB2B2B2
        t.ElementStroke := 0x323232
        t.CornerRadius := 10
    }

    static UseNativeFlat() {
        DM_Theme.Current.CornerRadius := 0
    }
}
