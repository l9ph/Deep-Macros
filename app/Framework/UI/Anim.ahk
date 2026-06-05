class DM_Anim {
    static _Timers := Map()

    static EaseOut(t) {
        t := DM_Utils_Clamp(t, 0, 1)
        return 1 - (1 - t) ** 3
    }

    static EaseOutBack(t) {
        t := DM_Utils_Clamp(t, 0, 1)
        c := 1.4
        return 1 + (c + 1) * (t - 1) ** 3 + c * (t - 1) ** 2
    }

    static _Stop(id) {
        if DM_Anim._Timers.Has(id) {
            try SetTimer(DM_Anim._Timers[id], 0)
            DM_Anim._Timers.Delete(id)
        }
    }

    static _Run(id, fn) {
        DM_Anim._Stop(id)
        DM_Anim._Timers[id] := fn
        SetTimer(fn, 16)
    }

    static FadeIn(hwnd, ms := 280) {
        if !hwnd
            return
        try WinSetTransparent(0, "ahk_id " hwnd)
        id := "fade_" hwnd
        data := { start: A_TickCount, ms: ms, hwnd: hwnd, id: id }
        DM_Anim._Run(id, (*) => DM_Anim._FadeStep(data))
    }

    static _FadeStep(data) {
        p := DM_Anim.EaseOut((A_TickCount - data.start) / data.ms)
        try WinSetTransparent(Round(p * 255), "ahk_id " data.hwnd)
        if (p >= 1) {
            try WinSetTransparent("Off", "ahk_id " data.hwnd)
            DM_Anim._Stop(data.id)
        }
    }

    static SlideIn(ctrl, targetY, ms := 320, offset := 28) {
        if !IsObject(ctrl)
            return
        id := "slide_" ctrl.Hwnd
        try ctrl.GetPos(, &y)
        startY := y + offset
        try ctrl.Move(, startY)
        data := { ctrl: ctrl, start: A_TickCount, ms: ms, startY: startY, targetY: targetY, id: id }
        DM_Anim._Run(id, (*) => DM_Anim._SlideStep(data))
    }

    static _SlideStep(data) {
        p := DM_Anim.EaseOutBack((A_TickCount - data.start) / data.ms)
        ny := Round(data.startY + (data.targetY - data.startY) * p)
        try data.ctrl.Move(, ny)
        if (p >= 1) {
            try data.ctrl.Move(, data.targetY)
            DM_Anim._Stop(data.id)
        }
    }

    static ToggleTo(toggle, on, ms := 180) {
        id := "tog_" toggle.knob.Hwnd
        t := DM_Theme.Current
        pad := 3
        endX := on ? (toggle.trackX + toggle.trackW - toggle.knobW - pad) : (toggle.trackX + pad)
        try toggle.knob.GetPos(&sx)
        data := { toggle: toggle, start: A_TickCount, ms: ms, startX: sx, endX: endX, on: on
            , onRgb: t.ToggleOn, offRgb: t.ToggleOff, id: id }
        DM_Anim._Run(id, (*) => DM_Anim._ToggleStep(data))
    }

    static _ToggleStep(data) {
        p := DM_Anim.EaseOut((A_TickCount - data.start) / data.ms)
        nx := Round(data.startX + (data.endX - data.startX) * p)
        try data.toggle.knob.Move(nx)
        rgb := data.on ? data.onRgb : data.offRgb
        try data.toggle.track.Opt("+Background" DM_Utils_HexBg(rgb))
        if (p >= 1)
            try data.toggle.knob.Move(data.endX)
        if (p >= 1)
            DM_Anim._Stop(data.id)
    }

    static BtnPulse(ctrl, flashRgb := "") {
        if !IsObject(ctrl)
            return
        t := DM_Theme.Current
        id := "pulse_" ctrl.Hwnd
        baseBg := ctrl.HasProp("_dmBg") ? ctrl._dmBg : t.BtnGhost
        flash := flashRgb != "" ? flashRgb : t.AccentHover
        try ctrl.Opt("+Background" DM_Utils_HexBg(flash))
        data := { ctrl: ctrl, start: A_TickCount, baseBg: baseBg, id: id }
        DM_Anim._Stop(id)
        DM_Anim._Timers[id] := (*) => DM_Anim._PulseStep(data)
        SetTimer(DM_Anim._Timers[id], 80)
    }

    static _PulseStep(data) {
        if (A_TickCount - data.start) >= 120 {
            try data.ctrl.Opt("+Background" DM_Utils_HexBg(data.baseBg))
            DM_Anim._Stop(data.id)
        }
    }

    static GrowWidth(ctrl, targetW, ms := 400) {
        if !IsObject(ctrl)
            return
        id := "grow_" ctrl.Hwnd
        try ctrl.GetPos(&x, &y)
        try ctrl.Move(x, y, 1)
        data := { ctrl: ctrl, x: x, y: y, start: A_TickCount, ms: ms, targetW: targetW, id: id }
        DM_Anim._Run(id, (*) => DM_Anim._GrowStep(data))
    }

    static _GrowStep(data) {
        p := DM_Anim.EaseOut((A_TickCount - data.start) / data.ms)
        nw := Max(2, Round(data.targetW * p))
        try data.ctrl.Move(data.x, data.y, nw)
        if (p >= 1) {
            try data.ctrl.Move(data.x, data.y, data.targetW)
            DM_Anim._Stop(data.id)
        }
    }
}

class DM_ToggleCtrl {
    __New(app, x, y, w, label, checked := false, rowH := 50) {
        t := DM_Theme.Current
        this.app := app
        this._checked := checked
        this.trackW := 48
        this.trackH := 24
        this.knobW := 18
        this.trackX := x + w - this.trackW - 14
        this.trackY := y + Round((rowH - this.trackH) / 2)
        pad := 3
        trackRgb := checked ? t.ToggleOn : t.ToggleOff
        this.track := app.gui.Add("Text",
            "x" this.trackX " y" this.trackY " w" this.trackW " h" this.trackH
            " Background" DM_Utils_HexBg(trackRgb))
        app._Track(this.track)
        kx := checked ? (this.trackX + this.trackW - this.knobW - pad) : (this.trackX + pad)
        ky := this.trackY + Round((this.trackH - this.knobW) / 2)
        this.knob := app.gui.Add("Text",
            "x" kx " y" ky " w" this.knobW " h" this.knobW " Background" DM_Utils_HexBg(t.ToggleKnob))
        app._Track(this.knob)
        this.hit := app.gui.Add("Text",
            "x" this.trackX " y" this.trackY " w" this.trackW " h" this.trackH " BackgroundTrans")
        app._Track(this.hit)
        this.hit.OnEvent("Click", ObjBindMethod(this, "Flip"))
        if (label != "") {
            lbl := app.gui.Add("Text", "x" (x + 14) " y" (y + Round((rowH - 22) / 2)) " w" (w - this.trackW - 36)
                " h24 +0x200 BackgroundTrans", label)
            lbl.SetFont(DM_Theme.Font(t.Text, 10), DM_Theme.FontName())
            app._Track(lbl)
        }
    }

    Flip(*) {
        this.SetState(!this._checked)
        if (this.HasProp("_onChange") && Type(this._onChange) = "Func")
            this._onChange.Call(this._checked)
    }

    SetState(on) {
        v := on ? true : false
        if (v = this._checked)
            return
        this._checked := v
        DM_Anim.ToggleTo(this, v)
    }

    Value {
        get => this._checked
        set => this.SetState(value)
    }
}
