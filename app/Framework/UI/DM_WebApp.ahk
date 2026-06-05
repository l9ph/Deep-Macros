#Include WebView2\WebView2.ahk

class DM_WebApp {
    __New(options := "") {
        this._web := true
        this.opts := DM_App._NormalizeOptions(options)
        this.configPath := this.opts.Get("onSaveConfigPath", "")
        this._values := Map()
        this._callbacks := Map()
        this._mappingLists := Map()
        this._tabs := Map()
        this._tabOrder := []
        this._rfActiveTab := ""
        this._rfCurrentTab := ""
        this._rfWindow := 0
        this._wvc := 0
        this._wvReady := false
        this._pageReady := false
        this._uiBuilt := false
        this._pendingPush := false
        this._BuildShell()
    }

    _BuildShell() {
        t := DM_Theme.Current
        title := this.opts.Has("title") ? this.opts["title"] : "Macros"
        w := this.opts.Has("width") ? this.opts["width"] : DM_Utils_ScaleForDpi(500)
        h := this.opts.Has("height") ? this.opts["height"] : DM_Utils_ScaleForDpi(475)
        this._winW := w
        this._winH := h

        this.gui := Gui("-Caption -SysMenu -DPIScale")
        this.gui.BackColor := t.Bg
        this._cornerRadius := t.HasProp("CornerRadius") ? t.CornerRadius : 10
        this.gui.OnEvent("Close", (gui, *) => (DM_HideConfigApp(), 1))
        this.gui.OnEvent("Size", ObjBindMethod(this, "_OnResize"))
        this.gui.Show("w" w " h" h)
        DM_Utils_RoundFrame(this.gui.Hwnd, this._cornerRadius)

        htmlPath := DM_GetFrameworkRoot() "\UI\assets\dm-rayfield.html"
        if !FileExist(htmlPath)
            throw Error("No se encuentra dm-rayfield.html en: " htmlPath, -1)
        this._htmlUri := "file:///" StrReplace(htmlPath, "\", "/")

        WebView2.create(this.gui.Hwnd, (wvc) => this._OnWebView(wvc))
    }

    _OnWebView(wvc) {
        this._wvc := wvc
        this.wv := wvc.CoreWebView2
        try this.wv.Settings.IsWebMessageEnabled := true
        try this.wv.Settings.AreDefaultContextMenusEnabled := false
        this.wv.add_WebMessageReceived((sender, args) => this._QueueWebMessage(args.TryGetWebMessageAsString()))
        try this.wv.DefaultBackgroundColor := 0x00000000
        try this._wvc.Fill()
        this.wv.Navigate(this._htmlUri)
        this.wv.add_NavigationCompleted((sender, args) => this._OnNavComplete(args))
    }

    _QueueWebMessage(msg) {
        if (msg = "" || msg = 0)
            return
        if (Type(msg) = "String" && SubStr(msg, 1, 1) = '"')
            msg := Trim(msg, '"')
        if (StrSplit(msg, Chr(31))[1] = "drag")
            return this._BeginWindowDrag()
        SetTimer(this._HandleWebMessage.Bind(this, msg), -1)
    }

    _HandleWebMessage(msg) {
        parts := StrSplit(msg, Chr(31))
        act := parts[1]
        if (act = "ready") {
            this._OnPageReady()
            return
        }
        if (act = "close") {
            SetTimer(ExitApp, -1)
            return
        }
        if (act = "hide")
            return this._HideWindow()
        if (act = "save") {
            cfgPath := this.opts.Get("onSaveConfigPath", "")
            SetTimer((*) => DM_ConfigApp_Save(this, cfgPath), -1)
            return
        }
        if (act = "tab" && parts.Length >= 2)
            return this._SelectTabWeb(parts[2])
        if (act = "toggle" && parts.Length >= 3)
            return this._OnToggle(parts[2], parts[3] = "1")
        if (act = "button" && parts.Length >= 2)
            return this._OnButton(parts[2])
        if (act = "input" && parts.Length >= 3)
            return this._OnInput(parts[2], parts[3])
        if (act = "slider" && parts.Length >= 3)
            return this._OnInput(parts[2], parts[3])
        if (act = "dropdown" && parts.Length >= 3)
            return this._OnInput(parts[2], parts[3])
        if (act = "capturebind" && parts.Length >= 2)
            return SetTimer(this._StartCaptureBind.Bind(this, parts[2]), -1)
        if (act = "manualbind" && parts.Length >= 3)
            return this._ApplyManualBind(parts[2], parts[3])
        if (act = "addmap" && parts.Length >= 2)
            return this._MappingListAdd(parts[2])
        if (act = "removemap" && parts.Length >= 3)
            return this._MappingListRemove(parts[2], parts[3])
    }

    _ApplyBindKey(id, key) {
        key := Trim(key)
        if (key = "" || key = "Escape")
            return false
        if !this._values.Has(id)
            this._values[id] := ""
        this._values[id] := key
        this._MappingListSetBind(id, key)
        if (this.configPath != "") {
            if (id = "AutoFlowState.Hotkey")
                IniWrite key, this.configPath, "AutoFlowState", "Hotkey"
            else if (id = "AutoFlowState.OutputKey")
                IniWrite key, this.configPath, "AutoFlowState", "OutputKey"
            else if RegExMatch(id, "^MouseButtons\.(\d+)\.(Trigger|Send)$", &mb)
                IniWrite key, this.configPath, "MouseButtons_" mb[1], mb[2]
            else if (id = "AssassinationDash.Hotkey")
                IniWrite key, this.configPath, "AssassinationDash", "Hotkey"
        }
        this._PushUI()
        if (id = "AutoFlowState.Hotkey" || id = "AutoFlowState.OutputKey"
            || RegExMatch(id, "^MouseButtons\.\d+\.(Trigger|Send)$"))
            try SetTimer(DMacros_ReloadModules, -1)
        return true
    }

    _StartCaptureBind(id) {
        DM_Toast("Press any key or mouse button… (Esc to cancel)", 2500)
        key := ""
        if DM_CaptureNextInput(&key) && this._ApplyBindKey(id, key)
            DM_Toast("Bound: " DM_BindDisplayName(key), 2000)
        else
            DM_Toast("Binding cancelled", 1500)
    }

    _ApplyManualBind(id, text) {
        if this._ApplyBindKey(id, text)
            DM_Toast("Set: " DM_BindDisplayName(Trim(text)), 2000)
        else
            DM_Toast("Invalid key name", 1500)
    }

    _OnNavComplete(args) {
        try {
            if (IsObject(args) && args.HasProp("IsSuccess") && !args.IsSuccess)
                return
        }
        if (!this._wvReady) {
            this._wvReady := true
            if (this.opts.Has("onReady"))
                this.opts["onReady"].Call(this)
            if (this._rfWindow && this._rfWindow.HasProp("_SelectFirstTab"))
                this._rfWindow._SelectFirstTab()
            DM_Anim.FadeIn(this.gui.Hwnd, 180)
        }
        this._pendingPush := true
        this._TryPushUI()
    }

    _OnPageReady() {
        this._pageReady := true
        this._TryPushUI()
    }

    _TryPushUI() {
        if (this._pendingPush && this._pageReady)
            this._PushUI()
    }

    _OnResize(*) {
        if (this.gui.Hwnd)
            DM_Utils_RoundFrame(this.gui.Hwnd, this.HasProp("_cornerRadius") ? this._cornerRadius : 10)
        if (this._wvc)
            try this._wvc.Fill()
    }

    _HideWindow() {
        DM_HideConfigApp()
    }

    _BeginWindowDrag() {
        hwnd := this.gui.Hwnd
        if !hwnd
            return
        DllCall("ReleaseCapture")
        PostMessage(0xA1, 2, 0, , "ahk_id " hwnd)
    }

    _OnToggle(id, v) {
        this._values[id] := v ? true : false
        if (this._callbacks.Has(id)) {
            cb := this._callbacks[id]
            if (Type(cb) = "Func")
                cb.Call(this._values[id])
        }
        if (this.configPath != "") {
            if (id = "AutoFlowState.Enabled")
                IniWrite v ? "1" : "0", this.configPath, "AutoFlowState", "Enabled"
            else if (id = "MouseButtons.Enabled")
                IniWrite v ? "1" : "0", this.configPath, "MouseButtons", "Enabled"
            else if (id = "AssassinationDash.Auto")
                IniWrite v ? "1" : "0", this.configPath, "AssassinationDash", "Auto"
        }
        if (id = "AutoFlowState.Enabled" || id = "MouseButtons.Enabled")
            try SetTimer(DMacros_ReloadModules, -1)
    }

    _OnButton(id) {
        if (this._callbacks.Has(id)) {
            cb := this._callbacks[id]
            if (Type(cb) = "Func")
                cb.Call()
        }
    }

    _OnInput(id, v) {
        this._values[id] := v
        if (this._callbacks.Has(id)) {
            cb := this._callbacks[id]
            if (Type(cb) = "Func")
                cb.Call(v)
        }
        if (this.configPath != "" && id = "AssassinationDash.Distance")
            IniWrite String(v), this.configPath, "AssassinationDash", "Distance"
    }

    _RF_RegisterTab(tab) {
        this._RegisterTab(tab.name)
    }

    _SelectTabWeb(name) {
        this._rfActiveTab := name
        this._rfCurrentTab := name
        for , tn in this._tabOrder {
            tab := this._tabs[tn]
            tab.active := (tn = name)
        }
    }

    _RegisterTab(name) {
        x := { name: name, active: false, sections: [] }
        this._tabs[name] := x
        this._tabOrder.Push(name)
        if (this._rfActiveTab = "")
            this._rfActiveTab := name, x.active := true
    }

    _CurrentTab() {
        if (this._rfCurrentTab != "" && this._tabs.Has(this._rfCurrentTab))
            return this._tabs[this._rfCurrentTab]
        if (this._tabOrder.Length)
            return this._tabs[this._tabOrder[1]]
        return 0
    }

    _AddSection(title) {
        tab := this._CurrentTab()
        if !IsObject(tab)
            return
        sec := { title: title, items: [] }
        tab.sections.Push(sec)
        return sec
    }

    _AddItem(item) {
        tab := this._CurrentTab()
        if !IsObject(tab) || !tab.sections.Length
            this._AddSection("")
        sec := tab.sections[tab.sections.Length]
        sec.items.Push(item)
    }

    WebCreateToggle(label, value, callback, id := "") {
        if (id = "")
            id := this._MakeId("toggle", label)
        this._values[id] := value ? true : false
        if (Type(callback) = "Func")
            this._callbacks[id] := callback
        this._AddItem({ type: "toggle", id: id, label: label, value: this._values[id] })
        return RF_WebElementRef(this, id, "toggle", this._values[id])
    }

    WebCreateButton(label, callback, id := "") {
        if (id = "")
            id := this._MakeId("btn", label)
        if (Type(callback) = "Func")
            this._callbacks[id] := callback
        this._AddItem({ type: "button", id: id, label: label })
        return RF_WebElementRef(this, id, "button", "")
    }

    WebCreateInput(label, value, placeholder, callback, id := "") {
        if (id = "")
            id := this._MakeId("input", label)
        this._values[id] := value
        if (Type(callback) = "Func")
            this._callbacks[id] := callback
        this._AddItem({ type: "input", id: id, label: label, value: value, placeholder: placeholder })
        return RF_WebElementRef(this, id, "input", value)
    }

    WebCreateResolution(label, width, height, idW := "", idH := "") {
        if (idW = "")
            idW := this._MakeId("res_w", label)
        if (idH = "")
            idH := this._MakeId("res_h", label)
        w := String(width), h := String(height)
        this._values[idW] := w
        this._values[idH] := h
        this._AddItem({ type: "resolution", label: label, idW: idW, idH: idH, width: w, height: h })
        return Map(
            "w", RF_WebElementRef(this, idW, "input", w),
            "h", RF_WebElementRef(this, idH, "input", h)
        )
    }

    WebCreateHint(text) {
        this._AddItem({ type: "hint", label: text })
    }

    WebCreateDivider() {
        this._AddItem({ type: "divider" })
    }

    WebCreateSlider(label, range, increment, value, suffix := "", callback := "", id := "", showWhen := "") {
        if (id = "")
            id := this._MakeId("slider", label)
        min := range is Array && range.Length >= 1 ? range[1] : 0
        max := range is Array && range.Length >= 2 ? range[2] : 100
        this._values[id] := value
        if (Type(callback) = "Func")
            this._callbacks[id] := callback
        item := {
            type: "slider",
            id: id,
            label: label,
            min: min,
            max: max,
            step: increment,
            value: value,
            suffix: suffix
        }
        if (IsObject(showWhen) && (showWhen is Map || showWhen.HasProp("id")))
            item.showWhen := showWhen
        this._AddItem(item)
        return RF_WebElementRef(this, id, "input", value)
    }

    WebCreateDropdown(label, options, current, callback := "", id := "", tooltip := "") {
        if (id = "")
            id := this._MakeId("dropdown", label)
        cur := current
        if (IsObject(cur) && cur is Array && cur.Length)
            cur := cur[1]
        this._values[id] := cur
        if (Type(callback) = "Func")
            this._callbacks[id] := callback
        item := {
            type: "dropdown",
            id: id,
            label: label,
            options: options,
            value: cur
        }
        if (tooltip != "")
            item.tooltip := tooltip
        this._AddItem(item)
        return RF_WebElementRef(this, id, "input", cur)
    }

    WebCreateAccordion(label, items, expanded := false, id := "") {
        if (id = "")
            id := this._MakeId("accordion", label)
        this._AddItem({
            type: "accordion",
            id: id,
            label: label,
            expanded: expanded ? true : false,
            items: items
        })
        return RF_WebElementRef(this, id, "accordion", expanded)
    }

    WebCreateKeybind(label, hotkey, id := "", showWhen := "") {
        if (id = "")
            id := this._MakeId("bind", label)
        hk := hotkey
        this._values[id] := hk
        item := {
            type: "keybind",
            id: id,
            label: label,
            bindKey: hk,
            bindValue: hk != "" ? DM_BindDisplayName(hk) : "Click to set"
        }
        if (IsObject(showWhen) && (showWhen is Map || showWhen.HasProp("id")))
            item.showWhen := showWhen
        this._AddItem(item)
        return RF_WebElementRef(this, id, "input", hk)
    }

    WebCreateToggleKeybind(label, enabled, hotkey, idToggle := "", idBind := "") {
        if (idToggle = "")
            idToggle := this._MakeId("toggle", label)
        if (idBind = "")
            idBind := this._MakeId("bind", label)
        this._values[idToggle] := enabled ? true : false
        this._values[idBind] := hotkey
        this._AddItem({
            type: "toggle_bind",
            label: label,
            idToggle: idToggle,
            idBind: idBind,
            toggleValue: this._values[idToggle],
            bindKey: hotkey,
            bindValue: hotkey != "" ? DM_BindDisplayName(hotkey) : "Click to set"
        })
        return Map(
            "toggle", RF_WebElementRef(this, idToggle, "toggle", this._values[idToggle]),
            "bind", RF_WebElementRef(this, idBind, "input", hotkey)
        )
    }

    WebCreateMappingList(listId, entries) {
        rows := []
        for e in entries {
            rows.Push(Map(
                "trigger", (Type(e) = "Map") ? e.Get("trigger", "") : "",
                "send", (Type(e) = "Map") ? e.Get("send", "") : ""
            ))
        }
        if !rows.Length
            rows.Push(Map("trigger", "", "send", ""))
        this._mappingLists[listId] := rows
        this._MappingListSyncValues(listId)
        this._AddItem({ type: "mapping_list", listId: listId })
        return listId
    }

    _MappingListSyncValues(listId) {
        if !this._mappingLists.Has(listId)
            return
        rows := this._mappingLists[listId]
        Loop rows.Length {
            i := A_Index
            row := rows[i]
            idT := listId "." i ".Trigger"
            idS := listId "." i ".Send"
            this._values[idT] := row["trigger"]
            this._values[idS] := row["send"]
        }
    }

    _MappingListUiItems(listId) {
        items := []
        if !this._mappingLists.Has(listId)
            return items
        rows := this._mappingLists[listId]
        canRemove := rows.Length > 1
        Loop rows.Length {
            i := A_Index
            idT := listId "." i ".Trigger"
            idS := listId "." i ".Send"
            trig := this._values.Has(idT) ? String(this._values[idT]) : rows[i]["trigger"]
            send := this._values.Has(idS) ? String(this._values[idS]) : rows[i]["send"]
            items.Push(Map(
                "listId", listId,
                "index", i,
                "label", "Tweak " i,
                "idTrigger", idT,
                "idSend", idS,
                "triggerKey", trig,
                "sendKey", send,
                "triggerValue", trig != "" ? DM_BindDisplayName(trig) : "Set",
                "sendValue", send != "" ? DM_BindDisplayName(send) : "Set",
                "canRemove", canRemove
            ))
        }
        return items
    }

    _MappingListSetBind(id, key) {
        if !RegExMatch(id, "^(.+)\.(\d+)\.(Trigger|Send)$", &m)
            return
        listId := m[1]
        idx := Integer(m[2])
        field := (m[3] = "Trigger") ? "trigger" : "send"
        if !this._mappingLists.Has(listId)
            return
        rows := this._mappingLists[listId]
        if (idx < 1 || idx > rows.Length)
            return
        rows[idx][field] := key
    }

    _MappingListAdd(listId) {
        if !this._mappingLists.Has(listId)
            this._mappingLists[listId] := []
        this._mappingLists[listId].Push(Map("trigger", "", "send", ""))
        this._MappingListSyncValues(listId)
        this._PushUI()
    }

    _MappingListRemove(listId, indexStr) {
        if !this._mappingLists.Has(listId)
            return
        rows := this._mappingLists[listId]
        idx := Integer(indexStr)
        if (rows.Length <= 1 || idx < 1 || idx > rows.Length)
            return
        rows.RemoveAt(idx)
        this._MappingListSyncValues(listId)
        this._PushUI()
        try SetTimer(DMacros_ReloadModules, -1)
    }

    _MakeId(prefix, label) {
        base := this._rfCurrentTab != "" ? this._rfCurrentTab : "main"
        s := StrLower(base "_" prefix "_" label)
        return RegExReplace(s, "[^\w]", "_")
    }

    _GetValue(id) {
        return this._values.Has(id) ? this._values[id] : false
    }

    _SetValue(id, v) {
        this._values[id] := v
        this._PushUI()
    }

    _SyncItemsFromValues() {
        for , tn in this._tabOrder {
            tab := this._tabs[tn]
            for sec in tab.sections {
                for it in sec.items {
                    if (it.type = "toggle_bind") {
                        if (this._values.Has(it.idToggle))
                            it.toggleValue := this._values[it.idToggle] ? true : false
                        if (this._values.Has(it.idBind)) {
                            hk := String(this._values[it.idBind])
                            it.bindKey := hk
                            it.bindValue := hk != "" ? DM_BindDisplayName(hk) : "Click to set"
                        }
                    } else if (it.type = "toggle" && this._values.Has(it.id)) {
                        it.value := this._values[it.id] ? true : false
                    } else if (it.type = "keybind" && this._values.Has(it.id)) {
                        hk := String(this._values[it.id])
                        it.bindKey := hk
                        it.bindValue := hk != "" ? DM_BindDisplayName(hk) : "Click to set"
                    } else if (it.type = "dropdown" && this._values.Has(it.id)) {
                        it.value := String(this._values[it.id])
                    } else if (it.type = "slider" && this._values.Has(it.id)) {
                        it.value := this._values[it.id]
                    } else if (it.type = "mapping_list") {
                        it.items := this._MappingListUiItems(it.listId)
                    }
                }
            }
        }
    }

    _BuildModel() {
        t := DM_Theme.Current
        tabs := []
        for , name in this._tabOrder
            tabs.Push(this._tabs[name])
        return Map(
            "title", this.opts.Has("title") ? this.opts["title"] : "Macros",
            "subtitle", this.opts.Has("subtitle") ? this.opts["subtitle"] : "",
            "theme", Map(
                "Bg", t.Bg, "Surface", t.Surface, "SurfaceAlt", t.SurfaceAlt,
                "RowBg", t.RowBg, "InputBg", t.InputBg, "Border", t.Border,
                "ElementStroke", t.HasProp("ElementStroke") ? t.ElementStroke : t.Border,
                "Text", t.Text, "TextMuted", t.TextMuted, "Accent", t.Accent,
                "AccentHover", t.AccentHover, "TabBg", t.TabBg, "TabText", t.TabText,
                "TabBgSelected", t.TabBgSelected, "TabTextSelected", t.TabTextSelected,
                "ToggleOn", t.ToggleOn, "ToggleOff", t.ToggleOff, "ToggleKnob", t.ToggleKnob
            ),
            "tabs", tabs
        )
    }

    _PushUI() {
        if !this._wvReady || !this.wv || !this._pageReady
            return
        this._SyncItemsFromValues()
        json := DM_WebApp._ToJson(this._BuildModel())
        try
            this.wv.PostWebMessageAsJson(json)
        catch {
            js := "window.dmApply(" json ")"
            try
                this.wv.ExecuteScriptAsync(js)
            catch {
            }
        }
    }

    static _JoinStr(parts) {
        out := ""
        for p in parts
            out .= p
        return out
    }

    static _ToJson(val) {
        if (Type(val) = "Map") {
            parts := ["{"]
            first := true
            for k, v in val {
                if !first
                    parts.Push(",")
                first := false
                parts.Push(DM_WebApp._Quote(k), ":", DM_WebApp._ToJson(v))
            }
            parts.Push("}")
            return DM_WebApp._JoinStr(parts)
        }
        if (IsObject(val) && !(val is Array)) {
            parts := ["{"]
            first := true
            for k in val.OwnProps() {
                if !first
                    parts.Push(",")
                first := false
                parts.Push(DM_WebApp._Quote(k), ":", DM_WebApp._ToJson(val.%k%))
            }
            parts.Push("}")
            return DM_WebApp._JoinStr(parts)
        }
        if (val is Array) {
            parts := ["["]
            first := true
            for v in val {
                if !first
                    parts.Push(",")
                first := false
                parts.Push(DM_WebApp._ToJson(v))
            }
            parts.Push("]")
            return DM_WebApp._JoinStr(parts)
        }
        if (val is Integer || val is Float)
            return val
        if (val = true)
            return "true"
        if (val = false)
            return "false"
        return DM_WebApp._Quote(String(val))
    }

    static _Quote(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        return '"' s '"'
    }

    Hwnd => this.gui.Hwnd
}

class RF_WebElementRef {
    __New(app, id, elemType, initial) {
        this.app := app
        this.id := id
        this._type := elemType
        this._initial := initial
    }

    Set(v) => (this.app._SetValue(this.id, v))

    CurrentValue {
        get => this.app._GetValue(this.id)
        set => this.Set(value)
    }

    Text {
        get => String(this.app._GetValue(this.id))
        set => this.app._SetValue(this.id, value)
    }
}
