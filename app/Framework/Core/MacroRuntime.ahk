global DM_Macro_ModuleKeys := Map()

DM_Macro_InRoblox() {
    try {
        exe := WinGetProcessName("A")
        return exe = "RobloxPlayerBeta.exe" || exe = "RobloxPlayer.exe"
    }
    return false
}

DM_Macro_RobloxActive() => DM_Macro_InRoblox()

DM_Macro_HkId(key, mousePassthrough := false) {
    k := Trim(key)
    if (k = "")
        return ""
    if RegExMatch(k, "i)^(LButton|RButton|MButton|XButton\d*|Wheel(?:Up|Down))$")
        return (mousePassthrough ? "~" : "") "$" k
    return k
}

DM_Macro_UnregisterModule(module) {
    global DM_Macro_ModuleKeys
    if !DM_Macro_ModuleKeys.Has(module)
        return
    for hk in DM_Macro_ModuleKeys[module] {
        try Hotkey hk, "Off"
    }
    DM_Macro_ModuleKeys.Delete(module)
}

DM_Macro_RegisterHotkeys(module, bindings, mousePassthrough := false) {
    global DM_Macro_ModuleKeys
    DM_Macro_UnregisterModule(module)
    keys := []
    if !IsObject(bindings) || bindings.Length = 0
        return

    for b in bindings {
        k := (Type(b) = "Map") ? b.Get("key", "") : ""
        fn := (Type(b) = "Map") ? b.Get("fn", "") : ""
        hid := DM_Macro_HkId(k, mousePassthrough)
        if (hid = "" || !(fn is Func))
            continue
        Hotkey hid, fn, "On"
        keys.Push(hid)
    }
    DM_Macro_ModuleKeys[module] := keys
}

DM_Macro_ModuleEnabled(configPath, section, default := "1") {
    return DM_Utils_Ini(configPath, section, "Enabled", default) = "1"
}

DM_Macro_SendKey(key) {
    k := Trim(key)
    if (k = "")
        return
    Send "{" k "}"
}
