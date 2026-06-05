
RF_Has(obj, key) {
    if (Type(obj) = "Map")
        return obj.Has(key)
    return obj.HasProp(key)
}

RF_Get(obj, key, default := "") {
    if (Type(obj) = "Map")
        return obj.Get(key, default)
    if (obj.HasProp(key))
        return obj.%key%
    return default
}

class RF_Library {
    CreateWindow(Settings, scriptDir := "", configPath := "", onSave := "", buildUI := "") {
        if (scriptDir = "")
            scriptDir := A_ScriptDir
        if (configPath = "")
            configPath := scriptDir "\Config"
        name := RF_Get(Settings, "Name", "Macros")
        sub := RF_Has(Settings, "LoadingSubtitle") ? RF_Get(Settings, "LoadingSubtitle", "") : ""
        DM_Theme.UseRayfield()
        opts := Map(
            "title", name,
            "subtitle", sub,
            "onSave", onSave,
            "onSaveConfigPath", configPath,
            "width", DM_Utils_ScaleForDpi(500),
            "height", DM_Utils_ScaleForDpi(520),
            "rayfield", true
        )
        if (Type(buildUI) = "Func")
            opts["onReady"] := (app) => this._OnReady(app, buildUI)
        app := DM_WebApp(opts)
        global DM_ActiveApp, App
        DM_ActiveApp := app
        App := app
        return app._rfWindow
    }

    _OnReady(app, buildUI) {
        win := RF_Window(app)
        app._rfWindow := win
        buildUI.Call(win)
        win._SelectFirstTab()
    }

    Notify(Data) => DM_Dialog.Notify(Data)

    Open(scriptDir, configPath, onSave, buildUI) {
        global DM_ActiveApp, App
        if (IsObject(DM_ActiveApp)) {
            try
                DM_ActiveApp.gui.Destroy()
            catch {
            }
        }
        return this.CreateWindow(Map("Name", "Macros"), scriptDir, configPath, onSave, buildUI)
    }
}

class RF_Window {
    __New(app) {
        this.app := app
        this.ConfigPath := app.configPath
        this._tabs := Map()
        this._tabOrder := []
        this._refs := Map()
    }

    SetRef(id, ref) {
        this._refs[id] := ref
    }

    GetRef(id) {
        return this._refs.Has(id) ? this._refs[id] : 0
    }

    CreateTab(Name) {
        tab := RF_Tab(this.app, Name, this)
        this._tabs[Name] := tab
        this._tabOrder.Push(Name)
        return tab
    }

    _SelectFirstTab() {
        if (this._tabOrder.Length)
            this._tabs[this._tabOrder[1]].Activate()
    }
}

class RF_Tab {
    __New(app, name, window) {
        this.app := app
        this.name := name
        this.window := window
        this._controls := []
        this._refs := Map()
        app._RF_RegisterTab(this)
    }

    _Begin() {
        this.app._rfCurrentTab := this.name
        if (this.app.HasProp("_web") && this.app._web)
            return
        if (this.app._rfTabs.Has(this.name))
            this.app._ly := this.app._rfTabs[this.name]._ly
    }

    _End() {
        if (this.app.HasProp("_web") && this.app._web)
            return
        if (this.app._rfTabs.Has(this.name))
            this.app._rfTabs[this.name]._ly := this.app._ly
    }

    _IsWeb() {
        return this.app.HasProp("_web") && this.app._web
    }

    CreateSection(SectionName) {
        this._Begin()
        if (this._IsWeb())
            this.app._AddSection(SectionName)
        else
            F.Section(this.app, SectionName)
        this._End()
        return this
    }

    CreateDivider() {
        this._Begin()
        if (this._IsWeb())
            this.app.WebCreateDivider()
        else
            F.Divider(this.app)
        this._End()
        return this
    }

    CreateLabel(LabelText) {
        this._Begin()
        if (this._IsWeb())
            this.app.WebCreateHint(LabelText)
        else
            F.Hint(this.app, LabelText)
        this._End()
        return this
    }

    CreateHint(LabelText) => this.CreateLabel(LabelText)

    CreateToggle(ToggleSettings) {
        this._Begin()
        name := RF_Get(ToggleSettings, "Name", "Toggle")
        val := RF_Get(ToggleSettings, "CurrentValue", false)
        cbFn := RF_Get(ToggleSettings, "Callback", "")
        id := RF_Get(ToggleSettings, "Id", "")
        if (id = "")
            id := RF_Get(ToggleSettings, "BindId", "")
        if (this._IsWeb()) {
            ref := this.app.WebCreateToggle(name, val, cbFn, id)
        } else {
            cb := F.RFToggle(this.app, name, val, cbFn)
            ref := RF_ElementRef(cb, val, "toggle")
            if (Type(cbFn) = "Func")
                cb._onChange := cbFn
        }
        this._refs[name] := ref
        this._End()
        return ref
    }

    CreateButton(ButtonSettings) {
        this._Begin()
        name := RF_Get(ButtonSettings, "Name", "Button")
        cbFn := RF_Get(ButtonSettings, "Callback", "")
        if (this._IsWeb())
            ref := this.app.WebCreateButton(name, cbFn)
        else {
            btn := F.RFButton(this.app, name, cbFn)
            ref := RF_ElementRef(btn, "", "button")
        }
        this._refs[name] := ref
        this._End()
        return ref
    }

    CreateMappingList(Settings) {
        this._Begin()
        listId := RF_Get(Settings, "ListId", "Mappings")
        entries := RF_Get(Settings, "Entries", [])
        if (this._IsWeb())
            this.app.WebCreateMappingList(listId, entries)
        this._End()
        return listId
    }

    CreateKeybind(Settings) {
        this._Begin()
        name := RF_Get(Settings, "Name", "Keybind")
        hk := RF_Get(Settings, "Hotkey", "")
        id := RF_Get(Settings, "BindId", "")
        showWhen := RF_Get(Settings, "ShowWhen", "")
        if (this._IsWeb()) {
            ref := this.app.WebCreateKeybind(name, hk, id, showWhen)
            this._End()
            return ref
        }
        this._End()
        return 0
    }

    CreateToggleKeybind(Settings) {
        this._Begin()
        name := RF_Get(Settings, "Name", "Bind")
        val := RF_Get(Settings, "CurrentValue", false)
        hk := RF_Get(Settings, "Hotkey", "")
        idT := RF_Get(Settings, "ToggleId", "")
        idB := RF_Get(Settings, "BindId", "")
        if (this._IsWeb()) {
            pair := this.app.WebCreateToggleKeybind(name, val, hk, idT, idB)
            this._End()
            return pair
        }
        ref := this.CreateToggle({ Name: name, CurrentValue: val })
        this._End()
        return Map("toggle", ref, "bind", 0)
    }

    CreateInput(InputSettings) {
        this._Begin()
        name := RF_Get(InputSettings, "Name", "Input")
        val := RF_Get(InputSettings, "CurrentValue", "")
        ph := RF_Get(InputSettings, "PlaceholderText", "")
        if (this._IsWeb())
            ref := this.app.WebCreateInput(name, val, ph, RF_Get(InputSettings, "Callback", ""))
        else {
            ed := F.RFInput(this.app, name, val, ph, RF_Get(InputSettings, "Callback", ""))
            ref := RF_ElementRef(ed, val, "input")
        }
        this._refs[name] := ref
        this._End()
        return ref
    }

    CreateSlider(SliderSettings) {
        this._Begin()
        name := RF_Get(SliderSettings, "Name", "Slider")
        rng := RF_Get(SliderSettings, "Range", [0, 100])
        inc := RF_Get(SliderSettings, "Increment", 1)
        cur := RF_Get(SliderSettings, "CurrentValue", rng[1])
        suf := RF_Get(SliderSettings, "Suffix", "")
        cbFn := RF_Get(SliderSettings, "Callback", "")
        id := RF_Get(SliderSettings, "Id", "")
        showWhen := RF_Get(SliderSettings, "ShowWhen", "")
        if (this._IsWeb()) {
            ref := this.app.WebCreateSlider(name, rng, inc, cur, suf, cbFn, id, showWhen)
        } else {
            sl := F.RFSlider(this.app, name, rng, inc, cur, suf, cbFn)
            ref := RF_ElementRef(sl, cur, "slider")
        }
        this._refs[name] := ref
        this._End()
        return ref
    }

    CreateDropdown(DropdownSettings) {
        this._Begin()
        name := RF_Get(DropdownSettings, "Name", "Dropdown")
        opts := RF_Get(DropdownSettings, "Options", ["A", "B"])
        cur := RF_Get(DropdownSettings, "CurrentOption", [opts[1]])
        if (Type(cur) = "String")
            cur := [cur]
        cbFn := RF_Get(DropdownSettings, "Callback", "")
        ddId := RF_Get(DropdownSettings, "DropdownId", "")
        if (this._IsWeb()) {
            ref := this.app.WebCreateDropdown(name, opts, cur[1], cbFn, ddId)
        } else {
            dd := F.RFDropdown(this.app, name, opts, cur[1], cbFn)
            ref := RF_ElementRef(dd, cur[1], "dropdown")
        }
        this._refs[name] := ref
        this._End()
        return ref
    }

    Activate() {
        if (this.app.HasProp("_web") && this.app._web)
            return this.app._SelectTabWeb(this.name)
        return this.app._RF_SelectTab(this.name)
    }
}

class RF_ElementRef {
    __New(ctrl, initial, elemType := "") {
        this._ctrl := ctrl
        this._initial := initial
        this._type := elemType
    }

    Set(v) {
        if (this._type = "slider" && this._ctrl.HasProp("SetValue"))
            this._ctrl.SetValue(v)
        else if (this._ctrl.HasProp("SetState"))
            this._ctrl.SetState(v)
        else if (this._ctrl.HasProp("Value"))
            this._ctrl.Value := v
    }

    CurrentValue {
        get {
            if (this._type = "slider" && this._ctrl.HasProp("_value"))
                return this._ctrl._value
            if (this._ctrl.HasProp("Value"))
                return this._ctrl.Value
            return this._initial
        }
        set => this.Set(value)
    }

    Text {
        get => this._ctrl.Value
        set => this._ctrl.Value := value
    }

    CurrentOption {
        get => [this._ctrl.Text]
        set {
            if (Type(value) = "Array")
                this._ctrl.Text := value[1]
            else
                this._ctrl.Text := value
        }
    }
}
