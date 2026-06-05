class DM_UI {
    static _OnBtnClick(guiCtrl, onClick, flash, *) {
        DM_Anim.BtnPulse(guiCtrl, flash)
        if (Type(onClick) = "Func")
            onClick.Call()
    }

    static _Layout(app) {
        t := DM_Theme.Current
        if !app.HasProp("_ly")
            app._ly := app.contentY
        x := app._fb + t.Pad
        w := app.clientW
        return { t: t, x: x, y: app._ly, w: w }
    }

    static _Advance(app, h, gap := 10) {
        app._ly += h + gap
    }

    static _Panel(app, x, y, w, h, fill, border := "", accentTop := false) {
        t := DM_Theme.Current
        if (accentTop) {
            acc := app.gui.Add("Text", "x" x " y" y " w" w " h3 Background" DM_Utils_HexBg(t.Accent))
            app._Track(acc)
            y += 3
            h -= 3
        }
        stroke := border != "" ? border : ""
        if (stroke != "") {
            bHex := DM_Utils_HexBg(stroke)
            fillHex := DM_Utils_HexBg(fill)
            frame := app.gui.Add("Text", "x" x " y" y " w" w " h" h " Background" bHex)
            app._Track(frame)
            inner := app.gui.Add("Text", "x" (x + 1) " y" (y + 1) " w" (w - 2) " h" (h - 2)
                " Background" fillHex)
            app._Track(inner)
            return inner
        }
        bg := app.gui.Add("Text", "x" x " y" y " w" w " h" h " Background" DM_Utils_HexBg(fill))
        app._Track(bg)
        return bg
    }

    static Title(app, text, opts := "") {
        L := DM_UI._Layout(app)
        o := opts != "" ? opts : "x" L.x " y" L.y " w" L.w " h32 +0x200 BackgroundTrans"
        ctrl := app.gui.Add("Text", o, text)
        ctrl.SetFont(DM_Theme.Font(L.t.Text, 16, true), DM_Theme.FontName())
        app._Track(ctrl)
        DM_UI._Advance(app, 32, 4)
        return ctrl
    }

    static Hint(app, text, opts := "") {
        L := DM_UI._Layout(app)
        o := opts != "" ? opts : "x" L.x " y" L.y " w" L.w " h18 +0x200 BackgroundTrans"
        ctrl := app.gui.Add("Text", o, text)
        ctrl.SetFont(DM_Theme.Font(L.t.TextMuted, 9), DM_Theme.FontName())
        app._Track(ctrl)
        DM_UI._Advance(app, 18, 6)
        return ctrl
    }

    static Header(app, title, subtitle := "") {
        DM_UI.Spacer(app, 6)
        DM_UI.Title(app, title)
        if (subtitle != "")
            DM_UI.Hint(app, subtitle)
        DM_UI.Divider(app, true)
    }

    static Section(app, label) {
        L := DM_UI._Layout(app)
        DM_UI._Advance(app, 4, 0)
        acc := app.gui.Add("Text", "x" L.x " y" L.y " w3 h16 Background" DM_Utils_HexBg(L.t.Accent))
        app._Track(acc)
        ctrl := app.gui.Add("Text", "x" (L.x + 9) " y" (L.y + 1) " w" (L.w - 12) " h20 +0x200 BackgroundTrans"
            , label)
        ctrl.SetFont(DM_Theme.Font(L.t.TextMuted, 9, true), DM_Theme.FontName())
        app._Track(ctrl)
        DM_UI._Advance(app, 24, 10)
        return ctrl
    }

    static Divider(app, animate := false) {
        L := DM_UI._Layout(app)
        ctrl := app.gui.Add("Text", "x" L.x " y" L.y " w" L.w " h1 Background" DM_Utils_HexBg(L.t.Border))
        app._Track(ctrl)
        DM_UI._Advance(app, 1, 12)
        return ctrl
    }

    static Spacer(app, h := 12) {
        DM_UI._Advance(app, h, 0)
    }

    static Card(app, title := "") {
        L := DM_UI._Layout(app)
        t := L.t
        app._cardX := L.x
        app._cardY := L.y
        app._cardW := L.w
        app._cardH := title != "" ? 108 : 72
        DM_UI._Panel(app, L.x, L.y, L.w, app._cardH, t.CardBg, t.CardBorder, true)
        if (title != "") {
            ctrl := app.gui.Add("Text", "x" (L.x + 14) " y" (L.y + 12) " w" (L.w - 28) " h20 +0x200 BackgroundTrans"
                , title)
            ctrl.SetFont(DM_Theme.Font(t.Text, 10, true), DM_Theme.FontName())
            app._Track(ctrl)
        }
        app._ly := L.y + (title != "" ? 40 : 16)
    }

    static CardEnd(app) {
        if !app.HasProp("_cardY")
            return
        app._ly := app._cardY + app._cardH + 14
        app._cardX := ""
        app._cardY := ""
    }

    static _Inner(app) {
        t := DM_Theme.Current
        x := app.HasProp("_cardX") ? app._cardX + 12 : app._fb + t.Pad
        w := app.HasProp("_cardW") ? app._cardW - 24 : app.clientW
        y := app._ly
        return { t: t, x: x, y: y, w: w }
    }

    static Toggle(app, label, checked := false) {
        I := DM_UI._Inner(app)
        rowH := 48
        DM_UI._Panel(app, I.x, I.y, I.w, rowH, I.t.RowBg, I.t.Border)
        tog := DM_ToggleCtrl(app, I.x, I.y, I.w, label, checked)
        app._ly := I.y + rowH + 8
        return tog
    }

    static Input(app, label, value := "", opts := "") {
        I := DM_UI._Inner(app)
        if (label != "") {
            lbl := app.gui.Add("Text", "x" I.x " y" I.y " w" I.w " h18 +0x200 BackgroundTrans", label)
            lbl.SetFont(DM_Theme.Font(I.t.TextMuted, 9), DM_Theme.FontName())
            app._Track(lbl)
            I.y += 22
        }
        o := opts != "" ? opts : "x" I.x " y" I.y " w" I.w " h" I.t.ControlH
        DM_UI._Panel(app, I.x, I.y, I.w, I.t.ControlH + 2, I.t.Border)
        ctrl := app.gui.Add("Edit", "x" (I.x + 2) " y" (I.y + 1) " w" (I.w - 4) " h" I.t.ControlH, value)
        ctrl.BackColor := I.t.InputBg
        app._Track(ctrl)
        app._ly := I.y + I.t.ControlH + 14
        return ctrl
    }

    static Button(app, text, onClick := "", primary := true) {
        L := DM_UI._Layout(app)
        w := primary ? 140 : 120
        h := L.t.ControlH
        bg := primary ? L.t.BtnPrimary : L.t.BtnGhost
        ctrl := app.gui.Add("Text", "x" L.x " y" L.y " w" w " h" h " Center Background"
            DM_Utils_HexBg(bg), text)
        ctrl._dmBg := bg
        ctrl.SetFont(DM_Theme.Font(primary ? 0xFFFFFF : L.t.Text, 10, true), DM_Theme.FontName())
        if (onClick != "") {
            flash := primary ? L.t.AccentHover : L.t.BtnGhostHover
            ctrl.OnEvent("Click", (guiCtrl, *) => DM_UI._OnBtnClick(guiCtrl, onClick, flash))
        }
        app._Track(ctrl)
        DM_UI._Advance(app, L.t.ControlH, 8)
        return ctrl
    }

    static Badge(app, text, tone := "accent") {
        L := DM_UI._Layout(app)
        c := L.t.Accent
        if (tone = "ok")
            c := L.t.Success
        else if (tone = "warn")
            c := L.t.Warning
        ctrl := app.gui.Add("Text", "x" L.x " y" L.y " w" (StrLen(text) * 7 + 24) " h22 Center Background"
            DM_Utils_HexBg(c), text)
        ctrl.SetFont(DM_Theme.Font(0xFFFFFF, 8, true), DM_Theme.FontName())
        app._Track(ctrl)
        DM_UI._Advance(app, 22, 8)
        return ctrl
    }

    static RF_Row(app, label := "", rowH := 44) {
        L := DM_UI._Layout(app)
        t := L.t
        stroke := t.HasProp("ElementStroke") ? t.ElementStroke : t.Border
        DM_UI._Panel(app, L.x, L.y, L.w, rowH, t.RowBg, stroke)
        if (label != "") {
            lbl := app.gui.Add("Text", "x" (L.x + 14) " y" (L.y + Round((rowH - 22) / 2)) " w" (L.w - 100)
                " h24 +0x200 BackgroundTrans", label)
            lbl.SetFont(DM_Theme.Font(t.Text, 10), DM_Theme.FontName())
            app._Track(lbl)
        }
        app._ly := L.y + rowH + 8
        return { x: L.x, y: L.y, w: L.w, h: rowH, t: t }
    }

    static RFToggle(app, label, checked := false, callback := "") {
        L := DM_UI._Layout(app)
        rowH := 50
        stroke := L.t.HasProp("ElementStroke") ? L.t.ElementStroke : L.t.Border
        DM_UI._Panel(app, L.x, L.y, L.w, rowH, L.t.RowBg, stroke)
        tog := DM_ToggleCtrl(app, L.x, L.y, L.w, label, checked, rowH)
        if (callback != "" && Type(callback) = "Func")
            tog._onChange := callback
        app._ly := L.y + rowH + 8
        return tog
    }

    static RFButton(app, label, callback := "") {
        L := DM_UI._Layout(app)
        t := L.t
        rowH := 44
        stroke := t.HasProp("ElementStroke") ? t.ElementStroke : t.Border
        DM_UI._Panel(app, L.x, L.y, L.w, rowH, t.RowBg, stroke)
        hit := app.gui.Add("Text", "x" L.x " y" L.y " w" L.w " h" rowH " BackgroundTrans")
        app._Track(hit)
        lbl := app.gui.Add("Text", "x" (L.x + 14) " y" (L.y + Round((rowH - 22) / 2)) " w" (L.w - 36)
            " h24 +0x200 BackgroundTrans", label)
        lbl.SetFont(DM_Theme.Font(t.Text, 10), DM_Theme.FontName())
        app._Track(lbl)
        ind := app.gui.Add("Text", "x" (L.x + L.w - 30) " y" (L.y + Round((rowH - 22) / 2))
            " w22 h24 Center +0x200 BackgroundTrans", "›")
        ind.SetFont(DM_Theme.Font(t.TextMuted, 11), DM_Theme.FontName())
        app._Track(ind)
        if (callback != "") {
            flash := t.BtnGhostHover
            hit.OnEvent("Click", (guiCtrl, *) => (
                DM_Anim.BtnPulse(guiCtrl, flash),
                Type(callback) = "Func" ? callback.Call() : ""
            ))
        }
        app._ly := L.y + rowH + 8
        return hit
    }

    static RFInput(app, label, value := "", placeholder := "", callback := "") {
        DM_UI.RF_Row(app, label, 28)
        L := DM_UI._Layout(app)
        t := L.t
        stroke := t.HasProp("ElementStroke") ? t.ElementStroke : t.Border
        DM_UI._Panel(app, L.x, L.y, L.w, t.ControlH + 4, t.InputBg, stroke)
        ed := app.gui.Add("Edit", "x" (L.x + 8) " y" (L.y + 2) " w" (L.w - 16) " h" t.ControlH, value)
        ed.BackColor := t.InputBg
        app._Track(ed)
        if (callback != "" && Type(callback) = "Func")
            ed.OnEvent("Change", (*) => callback.Call(ed.Value))
        app._ly := L.y + t.ControlH + 10
        return ed
    }

    static RFSlider(app, label, range, increment, current, suffix, callback := "") {
        row := DM_UI.RF_Row(app, label, 50)
        t := row.t
        minV := range[1], maxV := range[2]
        sld := app.gui.Add("Slider", "x" (row.x + 14) " y" (row.y + 28) " w" (row.w - 80) " h24"
            " Range" minV "-" maxV " TickInterval" increment, current)
        app._Track(sld)
        valLbl := app.gui.Add("Text", "x" (row.x + row.w - 60) " y" (row.y + 28) " w50 h24 Center +0x200 BackgroundTrans"
            , current suffix)
        valLbl.SetFont(DM_Theme.Font(t.TextMuted, 9), DM_Theme.FontName())
        app._Track(valLbl)
        obj := { _value: current, _rowCtrl: sld, _lbl: valLbl, _suffix: suffix }
        obj.SetValue := (v) => (sld.Value := v, valLbl.Text := v suffix, obj._value := v)
        sld.OnEvent("Change", (*) => (
            obj._value := sld.Value,
            valLbl.Text := sld.Value suffix,
            callback != "" && Type(callback) = "Func" ? callback.Call(sld.Value) : ""
        ))
        app._ly := row.y + row.h + 8
        return obj
    }

    static RFDropdown(app, label, options, current, callback := "") {
        row := DM_UI.RF_Row(app, label, 44)
        dd := app.gui.Add("DropDownList", "x" (row.x + row.w - 180) " y" (row.y + 10) " w170 h100 Choose1", options)
        try dd.Text := current
        app._Track(dd)
        if (callback != "" && Type(callback) = "Func")
            dd.OnEvent("Change", (*) => callback.Call([dd.Text]))
        return dd
    }

    static Label(app, text, opts := "") => DM_UI.Hint(app, text, opts)
    static Muted(app, text, opts := "") => DM_UI.Hint(app, text, opts)
    static Checkbox(app, text, checked := false, opts := "") => DM_UI.Toggle(app, text, checked)
}

class DM_Components extends DM_UI {
}
