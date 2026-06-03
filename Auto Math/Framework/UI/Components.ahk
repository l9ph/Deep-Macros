; Controles reutilizables con estilo unificado
class DM_Components {
    static Label(parent, text, opts := "") {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " y" t.Pad " w280 h20 +0x200")
        ctrl := parent.gui.Add("Text", o, text)
        parent.gui.SetFont(DM_Theme.Font(t.TextMuted, 9), t.FontUI)
        ctrl.SetFont(DM_Theme.Font(t.TextMuted, 9))
        parent.gui.SetFont(DM_Theme.Font(t.Text, 10), t.FontUI)
        parent._Track(ctrl)
        return ctrl
    }

    static Title(parent, text, opts := "") {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " w360 h28 +0x200")
        ctrl := parent.gui.Add("Text", o, text)
        ctrl.SetFont(DM_Theme.Font(t.Text, 14, true))
        parent._Track(ctrl)
        return ctrl
    }

    static Muted(parent, text, opts := "") {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " w360 h18 +0x200")
        ctrl := parent.gui.Add("Text", o, text)
        ctrl.SetFont(DM_Theme.Font(t.TextMuted, 9))
        parent._Track(ctrl)
        return ctrl
    }

    static Input(parent, value := "", opts := "") {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " w360 h" t.ControlH)
        ctrl := parent.gui.Add("Edit", o, value)
        ctrl.BackColor := t.SurfaceAlt
        parent._Track(ctrl)
        return ctrl
    }

    static Checkbox(parent, text, checked := false, opts := "") {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " w360 h24")
        ctrl := parent.gui.Add("Checkbox", o, text)
        ctrl.Value := checked
        parent._Track(ctrl)
        return ctrl
    }

    static Button(parent, text, onClick := "", opts := "", primary := true) {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " w120 h" t.ControlH)
        ctrl := parent.gui.Add("Button", o, text)
        if (onClick != "")
            ctrl.OnEvent("Click", onClick)
        parent._Track(ctrl)
        return ctrl
    }

    static Card(parent, title := "", opts := "") {
        t := DM_Theme.Current
        o := DM_Components._Opts(opts, "x" t.Pad " w360 h120")
        label := title != "" ? " " title : ""
        ctrl := parent.gui.Add("GroupBox", o, label)
        parent._Track(ctrl)
        return ctrl
    }

    static Spacer(parent, h := 8) {
        t := DM_Theme.Current
        ctrl := parent.gui.Add("Text", "x" t.Pad " w1 h" h, "")
        parent._Track(ctrl)
        return ctrl
    }

    static _Opts(user, defaults) {
        return user != "" ? user : defaults
    }
}
