class DM_Dialog {
    static Alert(title, message, icon := "i") {
        t := DM_Theme.Current
        g := Gui("+AlwaysOnTop -MinimizeBox", title)
        DM_Theme.ApplyGui(g, true)
        g.SetFont(DM_Theme.Font(t.Text, 10), DM_Theme.FontName())
        g.Add("Text", "x20 y20 w320 h60 +0x200", message)
        g.Add("Button", "x260 y90 w80 h32 Default", "OK").OnEvent("Click", (*) => g.Destroy())
        g.Show("w360 h140")
        WinWaitClose g
    }

    static Confirm(title, message, &result, parentGui := "") {
        t := DM_Theme.Current
        result := false
        g := Gui("+AlwaysOnTop -MinimizeBox", title)
        if (parentGui != "")
            g.Opt("+Owner" parentGui.Hwnd)
        DM_Theme.ApplyGui(g, true)
        g.SetFont(DM_Theme.Font(t.Text, 10), DM_Theme.FontName())
        g.Add("Text", "x20 y20 w320 h60 +0x200", message)
        g.Add("Button", "x140 y90 w80 h32", "Cancel").OnEvent("Click", (*) => (result := false, g.Destroy()))
        g.Add("Button", "x230 y90 w90 h32 Default", "Aceptar").OnEvent("Click", (*) => (result := true, g.Destroy()))
        g.Show("w360 h140")
        WinWaitClose g
        return result
    }

    static Notify(Data) {
        t := DM_Theme.Current
        title := RF_Get(Data, "Title", "Aviso")
        content := RF_Get(Data, "Content", "")
        duration := Integer(RF_Get(Data, "Duration", 7)) * 1000
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        g.BackColor := t.HasProp("SurfaceAlt") ? t.SurfaceAlt : t.Surface
        g.SetFont(DM_Theme.Font(t.Text, 10, true), DM_Theme.FontName())
        g.Add("Text", "x14 y10 w300 h20 +0x200", title)
        g.SetFont(DM_Theme.Font(t.TextMuted, 9), DM_Theme.FontName())
        g.Add("Text", "x14 y32 w300 h40 +0x200", content)
        g.Show("AutoSize NoActivate")
        DM_Anim.FadeIn(g.Hwnd, 220)
        WinGetPos(, , &gw, &gh, g)
        WinMove A_ScreenWidth - gw - 20, 40, , , g
        SetTimer ((*) => g.Destroy()), -duration
    }

    static Toast(message, durationMs := 2200) {
        Persistent(true)
        t := DM_Theme.Current
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        g.BackColor := t.SurfaceAlt
        g.OnEvent("Close", (*) => g.Destroy())
        g.SetFont(DM_Theme.Font(t.Text, 9), DM_Theme.FontName())
        g.Add("Text", "x16 y12 w280 h24 +0x200 Center", message)
        g.Show("AutoSize NoActivate")
        WinGetPos(, , &gw, &gh, g)
        x := A_ScreenWidth - gw - 24
        y := A_ScreenHeight - gh - 48
        WinMove x, y, , , g
        SetTimer ((*) => g.Destroy()), -durationMs
    }
}
