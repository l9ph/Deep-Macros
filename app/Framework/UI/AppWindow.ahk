class DM_App {
    __New(options := "") {
        this.opts := DM_App._NormalizeOptions(options)
        this.controls := []
        this._footerButtons := []
        this._hasSub := false
        this.configPath := this.opts.Get("onSaveConfigPath", "")
        this._Build()
    }

    static _NormalizeOptions(options) {
        if (Type(options) = "String")
            return Map("title", options)
        if (Type(options) = "Map")
            return options
        return Map()
    }

    _Build() {
        t := DM_Theme.Current
        fb := t.FrameBorder
        tb := t.TitleBarH
        title := this.opts.Has("title") ? this.opts["title"] : "Macros"
        w := this.opts.Has("width") ? this.opts["width"] : DM_Utils_ScaleForDpi(440)
        h := this.opts.Has("height") ? this.opts["height"] : DM_Utils_ScaleForDpi(520)
        topHex := DM_Utils_HexBg(t.HasProp("Topbar") ? t.Topbar : t.Surface)
        surfHex := topHex
        bgHex := DM_Utils_HexBg(t.Bg)
        borderHex := DM_Utils_HexBg(t.Border)

        subtitle := this.opts.Has("subtitle") ? this.opts["subtitle"] : ""
        if (subtitle != "")
            tb := DM_Utils_ScaleForDpi(t.TitleBarSubH)

        this.gui := Gui("-Caption -SysMenu -DPIScale")
        this.gui.BackColor := t.Border
        this.gui.SetFont(DM_Theme.Font(t.Text, 10), DM_Theme.FontName())
        this.gui.OnEvent("Close", (*) => ExitApp())

        innerW := w - fb * 2
        headY := fb + tb
        footerY := h - fb - t.FooterH
        bodyH := footerY - headY
        closeW := 46
        titleW := innerW - closeW - t.Pad

        this._titleBarBg := this.gui.Add("Text", "x0 y0 w" (w - closeW) " h" (fb + tb) " Background" surfHex)
        this._titleBarBg.OnEvent("Click", ObjBindMethod(this, "_Drag"))

        closeHex := DM_Utils_HexBg(t.SurfaceAlt)
        this._closeBg := this.gui.Add("Text", "x" (w - closeW) " y" fb " w" closeW " h" (fb + tb)
            " Background" closeHex)
        this._btnClose := this.gui.Add("Text", "x" (w - closeW) " y" (fb + 8) " w" closeW " h24 Center BackgroundTrans"
            , "✕")
        this._btnClose.SetFont(DM_Theme.Font(t.TextMuted, 11), DM_Theme.FontName())
        this._btnClose.OnEvent("Click", (*) => ExitApp())

        titleY := fb + 10
        this._titleCtrl := this.gui.Add("Text", "x" (fb + t.Pad) " y" titleY " w" titleW
            " h22 +0x200 BackgroundTrans", title)
        this._titleCtrl.SetFont(DM_Theme.Font(t.Text, 13, true), DM_Theme.FontName())
        this._titleCtrl.OnEvent("Click", ObjBindMethod(this, "_Drag"))

        if (subtitle != "") {
            this._hasSub := true
            subY := fb + 34
            this._subCtrl := this.gui.Add("Text", "x" (fb + t.Pad) " y" subY " w" titleW
                " h16 +0x200 BackgroundTrans", subtitle)
            this._subCtrl.SetFont(DM_Theme.Font(t.TextMuted, 9), DM_Theme.FontName())
            this._subCtrl.OnEvent("Click", ObjBindMethod(this, "_Drag"))
            titleSepY := fb + tb - 8
            this._titleSep := this.gui.Add("Text", "x" fb " y" titleSepY " w" innerW " h1 Background"
                DM_Utils_HexBg(t.Border))
        }

        this._sep := this.gui.Add("Text", "x" fb " y" headY " w" innerW " h1 Background" borderHex)
        this._bodyBg := this.gui.Add("Text", "x" fb " y" (headY + 1) " w" innerW " h" (bodyH - 1)
            " Background" bgHex)
        this._footerBg := this.gui.Add("Text", "x" fb " y" footerY " w" innerW " h" t.FooterH " Background"
            surfHex)

        this._rfMode := this.opts.Get("rayfield", false)
        this._rfTabs := Map()
        this._rfTabOrder := []
        this._rfActiveTab := ""
        this._rfTabX := fb + t.Pad
        tabBarH := this._rfMode ? 36 : 0
        this.contentY := headY + 14 + tabBarH + 8
        this._tabBarY := headY + 12
        this._tabBarH := tabBarH
        this._ly := this.contentY
        this.contentGui := this.gui
        this.clientW := innerW - t.Pad * 2
        this._fb := fb
        this._tb := tb
        this._winW := w
        this._winH := h
        this._footerY := footerY

        if (this.opts.Has("onReady"))
            this.opts["onReady"].Call(this)

        cfgPath := this.opts.Get("onSaveConfigPath", "")
        onSaveFn := this.opts.Get("onSave", "")
        this._BuildFooter("Guardar", "Ocultar",
            onSaveFn != "" ? ((*) => DM_ConfigApp_Save(this, cfgPath)) : "",
            DM_HideConfigApp)

        this.gui.Show("w" w " h" h)
        DM_Utils_SquareFrame(this.gui.Hwnd)
        DM_Anim.FadeIn(this.gui.Hwnd, 220)
    }

    _FooterBtn(x, y, w, h, text, onClick, primary := false) {
        t := DM_Theme.Current
        if (primary) {
            bg := t.BtnPrimary
            ctrl := this.gui.Add("Text", "x" x " y" y " w" w " h" h " Center Background" DM_Utils_HexBg(bg), text)
            ctrl._dmBg := bg
            ctrl.SetFont(DM_Theme.Font(0xFFFFFF, 10, true), DM_Theme.FontName())
        } else {
            ctrl := this.gui.Add("Text", "x" x " y" y " w" w " h" h " Center +0x200 BackgroundTrans", text)
            ctrl._dmBg := t.BtnGhost
            ctrl.SetFont(DM_Theme.Font(t.TextMuted, 10), DM_Theme.FontName())
        }
        if (onClick != "") {
            flash := primary ? t.AccentHover : t.BtnGhostHover
            ctrl.OnEvent("Click", (guiCtrl, *) => DM_UI._OnBtnClick(guiCtrl, onClick, flash))
        }
        return ctrl
    }

    _BuildFooter(primaryText, secondaryText, onPrimary, onSecondary) {
        this._footerButtons := []
        t := DM_Theme.Current
        w := this._winW
        fb := this._fb
        y := this._footerY + Round((t.FooterH - t.ControlH) / 2)
        btnW := 118
        gap := 10
        if (secondaryText != "") {
            secX := w - fb - t.Pad - btnW * 2 - gap
            sec := this._FooterBtn(secX, y, btnW, t.ControlH, secondaryText, onSecondary, false)
            this._footerButtons.Push(sec)
        }
        if (primaryText != "") {
            priX := w - fb - t.Pad - btnW
            pri := this._FooterBtn(priX, y, btnW, t.ControlH, primaryText, onPrimary, true)
            this._footerButtons.Push(pri)
        }
    }

    _Drag(*) {
        PostMessage(0xA1, 2, 0,, this.gui.Hwnd)
    }

    _Track(ctrl) {
        this.controls.Push(ctrl)
        if (this._rfMode && this.HasProp("_rfCurrentTab") && this._rfCurrentTab != ""
            && this._rfTabs.Has(this._rfCurrentTab)) {
            tab := this._rfTabs[this._rfCurrentTab]
            tab.controls.Push(ctrl)
            try ctrl.Visible := (this._rfCurrentTab = this._rfActiveTab)
        }
    }

    _RF_RegisterTab(tab) {
        t := DM_Theme.Current
        name := tab.name
        x := this._rfTabX
        for , tn in this._rfTabOrder {
            if this._rfTabs.Has(tn)
                x += this._rfTabs[tn].btnW + 8
        }
        btnW := Max(76, StrLen(name) * 8 + 32)
        tab.btnW := btnW
        bg := DM_Utils_HexBg(t.TabBg)
        btn := this.gui.Add("Text", "x" x " y" this._tabBarY " w" btnW " h" this._tabBarH
            " Center +0x200 Background" bg, name)
        btn.SetFont(DM_Theme.Font(t.TabText, 9), DM_Theme.FontName())
        btn._rfTabName := name
        btn._dmBg := t.TabBg
        btn._dmBgSel := t.TabBgSelected
        btn.OnEvent("Click", (guiCtrl, *) => this._RF_SelectTab(guiCtrl._rfTabName))
        this._Track(btn)
        tab.btn := btn
        tab.controls := []
        tab._ly := this.contentY
        this._rfTabs[name] := tab
        this._rfTabOrder.Push(name)
        if (this._rfActiveTab = "")
            this._rfActiveTab := name
    }

    _RF_SelectTab(name) {
        if !this._rfTabs.Has(name)
            return
        t := DM_Theme.Current
        for , tn in this._rfTabOrder {
            tab := this._rfTabs[tn]
            on := (tn = name)
            for , c in tab.controls {
                try c.Visible := on
            }
            try {
                if (on) {
                    tab.btn.Opt("+Background" DM_Utils_HexBg(t.TabBgSelected))
                    tab.btn.SetFont(DM_Theme.Font(t.TabTextSelected, 9, true), DM_Theme.FontName())
                } else {
                    tab.btn.Opt("+Background" DM_Utils_HexBg(tab.btn._dmBg))
                    tab.btn.SetFont(DM_Theme.Font(t.TabText, 9), DM_Theme.FontName())
                }
            }
        }
        this._rfActiveTab := name
        this._rfCurrentTab := name
        this._ly := this._rfTabs[name]._ly
    }

    Hwnd => this.gui.Hwnd
}
