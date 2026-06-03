; Ventana principal — sensación de mini aplicación (.exe sin compilar)
class DM_App {
    __New(options := "") {
        this.opts := DM_App._NormalizeOptions(options)
        this.controls := []
        this._footerButtons := []
        this._primaryText := ""
        this._secondaryText := ""
        this._onPrimary := ""
        this._onSecondary := ""
        this.contentY := DM_Theme.Current.HeaderH + DM_Theme.Current.Pad
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
        title := this.opts.Has("title") ? this.opts["title"] : "Deep-Macros"
        w := this.opts.Has("width") ? this.opts["width"] : DM_Utils_ScaleForDpi(440)
        h := this.opts.Has("height") ? this.opts["height"] : DM_Utils_ScaleForDpi(560)

        this.gui := Gui("+Resize -MaximizeBox +MinSize440x400", title)
        DM_Theme.ApplyGui(this.gui)
        this.gui.SetFont(DM_Theme.Font(t.Text, 10), t.FontUI)
        this.gui.OnEvent("Close", ObjBindMethod(this, "_OnClose"))
        this.gui.OnEvent("Size", ObjBindMethod(this, "_OnResize"))

        if (this.opts.Has("icon") && FileExist(this.opts["icon"]))
            this.gui.SetIcon(this.opts["icon"])

        ; Barra superior (chrome)
        this._headerBg := this.gui.Add("Text", "x0 y0 w" w " h" t.HeaderH " Background" Format("{:06X}", t.Surface))
        this._titleCtrl := this.gui.Add("Text", "x" t.Pad " y16 w" (w - t.Pad * 2) " h24 +0x200", title)
        this._titleCtrl.SetFont(DM_Theme.Font(t.Text, 13, true))

        subtitle := this.opts.Has("subtitle") ? this.opts["subtitle"] : ""
        if (subtitle != "") {
            this._subCtrl := this.gui.Add("Text", "x" t.Pad " y38 w" (w - t.Pad * 2) " h16 +0x200", subtitle)
            this._subCtrl.SetFont(DM_Theme.Font(t.TextMuted, 8))
        }

        ; Línea separadora
        this._sep := this.gui.Add("Text", "x0 y" t.HeaderH " w" w " h1 Background" Format("{:06X}", t.Border))

        ; Área de contenido (referencia Y para controles del usuario)
        this.contentGui := this.gui
        this.clientW := w - t.Pad * 2
        this._clientH := h - t.HeaderH - t.FooterH - t.Pad

        ; Footer
        footerY := h - t.FooterH
        this._footerBg := this.gui.Add("Text", "x0 y" footerY " w" w " h" t.FooterH " Background" Format("{:06X}", t.Surface))
        this._footerY := footerY

        if (this.opts.Has("onReady"))
            this.opts["onReady"].Call(this)

        this._LayoutFooter()
        this.gui.Show("w" w " h" h)
    }

    _Track(ctrl) {
        this.controls.Push(ctrl)
    }

    Add(fn) {
        fn.Call(this)
        return this
    }

    SetFooter(primaryText := "Guardar", secondaryText := "Cancelar", onPrimary := "", onSecondary := "") {
        this._primaryText := primaryText
        this._secondaryText := secondaryText
        this._onPrimary := onPrimary
        this._onSecondary := onSecondary
        this._RebuildFooter()
        return this
    }

    _RebuildFooter() {
        for btn in this._footerButtons
            try btn.ctrl.Destroy()
        this._footerButtons := []
        t := DM_Theme.Current
        w := this.gui.Size.w
        y := this._footerY + (t.FooterH - t.ControlH) // 2
        if (this._secondaryText != "") {
            sec := this.gui.Add("Button", "x" (w - t.Pad - 240) " y" y " w110 h" t.ControlH, this._secondaryText)
            if (this._onSecondary != "")
                sec.OnEvent("Click", this._onSecondary)
            this._footerButtons.Push({ ctrl: sec })
        }
        if (this._primaryText != "") {
            pri := this.gui.Add("Button", "x" (w - t.Pad - 120) " y" y " w110 h" t.ControlH " Default", this._primaryText)
            if (this._onPrimary != "")
                pri.OnEvent("Click", this._onPrimary)
            this._footerButtons.Push({ ctrl: pri })
        }
    }

    _LayoutFooter() {
        if !this._footerButtons.Length
            return
        t := DM_Theme.Current
        w := this.gui.Size.w
        y := this._footerY + Round((t.FooterH - t.ControlH) / 2)
        idx := 0
        for item in this._footerButtons {
            idx++
            x := w - t.Pad - (120 * idx) - (10 * (idx - 1))
            item.ctrl.Move(x, y)
        }
    }

    _OnResize(gui, minMax, width, height) {
        if (minMax = -1)
            return
        t := DM_Theme.Current
        this._headerBg.Move(, , width)
        this._sep.Move(, , width)
        this._footerBg.Move(0, height - t.FooterH, width)
        this._footerY := height - t.FooterH
        this._LayoutFooter()
        if (this.opts.Has("onResize"))
            this.opts["onResize"].Call(this, width, height)
    }

    _OnClose(*) {
        if (this.opts.Has("onClose"))
            this.opts["onClose"].Call(this)
        if (this.opts.Get("exitOnClose", false))
            ExitApp()
    }

    Show() => this.gui.Show()

    Hide() => this.gui.Hide()

    Close() {
        this.gui.Destroy()
        if (this.opts.Has("onClose"))
            this.opts["onClose"].Call(this)
    }

    Hwnd => this.gui.Hwnd
}
