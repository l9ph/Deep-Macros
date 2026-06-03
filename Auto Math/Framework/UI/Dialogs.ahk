; Diálogos modales estilo app
class DM_Dialog {
    static Alert(title, message, icon := "i") {
        t := DM_Theme.Current
        g := Gui("+AlwaysOnTop -MinimizeBox", title)
        DM_Theme.ApplyGui(g, true)
        g.SetFont(DM_Theme.Font(t.Text, 10), t.FontUI)
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
        g.SetFont(DM_Theme.Font(t.Text, 10), t.FontUI)
        g.Add("Text", "x20 y20 w320 h60 +0x200", message)
        g.Add("Button", "x140 y90 w80 h32", "Cancel").OnEvent("Click", (*) => (result := false, g.Destroy()))
        g.Add("Button", "x230 y90 w90 h32 Default", "Aceptar").OnEvent("Click", (*) => (result := true, g.Destroy()))
        g.Show("w360 h140")
        WinWaitClose g
        return result
    }

    static Toast(message, durationMs := 2200) {
        t := DM_Theme.Current
        g := Gui("-Caption +AlwaysOnTop +ToolWindow +E0x20")
        g.BackColor := t.SurfaceAlt
        g.SetFont(DM_Theme.Font(t.Text, 9), t.FontUI)
        g.Add("Text", "x16 y12 w280 h24 +0x200 Center", message)
        g.Show("AutoSize NoActivate")
        x := A_ScreenWidth - g.Size.w - 24
        y := A_ScreenHeight - g.Size.h - 48
        WinMove x, y, , , g
        SetTimer ((*) => g.Destroy()), -durationMs
    }
}
