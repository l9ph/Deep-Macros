AutoFlowState_MODULE := "AutoFlowState"
global AutoFlowState_Hotkey := ""

AutoFlowState_BuildUI(Tab, Win) {
    cfg := Win.ConfigPath
    Tab.CreateSection("Auto Flow State")
    pair := Tab.CreateToggleKeybind({
        Name: "Trigger",
        CurrentValue: DM_Utils_Ini(cfg, "AutoFlowState", "Enabled", "1") = "1",
        Hotkey: DM_Utils_Ini(cfg, "AutoFlowState", "Hotkey", ""),
        ToggleId: "AutoFlowState.Enabled",
        BindId: "AutoFlowState.Hotkey"
    })
    Win.SetRef("AutoFlowState.Enabled", pair["toggle"])
    Win.SetRef("AutoFlowState.Hotkey", pair["bind"])
    Win.SetRef("AutoFlowState.OutputKey", Tab.CreateKeybind({
        Name: "Flow State Slot",
        Hotkey: DM_Utils_Ini(cfg, "AutoFlowState", "OutputKey", ""),
        BindId: "AutoFlowState.OutputKey"
    }))
}

AutoFlowState_Save(Win, configPath) {
    t := Win.GetRef("AutoFlowState.Enabled")
    if IsObject(t)
        IniWrite t.CurrentValue ? "1" : "0", configPath, "AutoFlowState", "Enabled"
    b := Win.GetRef("AutoFlowState.Hotkey")
    if IsObject(b)
        IniWrite Trim(b.Text), configPath, "AutoFlowState", "Hotkey"
    o := Win.GetRef("AutoFlowState.OutputKey")
    if IsObject(o)
        IniWrite Trim(o.Text), configPath, "AutoFlowState", "OutputKey"
}

AutoFlowState_Stop() {
    global AutoFlowState_Hotkey
    if (AutoFlowState_Hotkey != "")
        try Hotkey AutoFlowState_Hotkey, "Off"
    AutoFlowState_Hotkey := ""
    try HotIf
}

AutoFlowState_ToHotkey(key) {
    k := Trim(key)
    if RegExMatch(k, "i)^(LButton|RButton|MButton|XButton\d*|Wheel(?:Up|Down))$")
        return "~$" k
    return k
}

AutoFlowState_Fire(*) {
    global DM_ConfigPath
    if !DM_Macro_InRoblox()
        return
    sendKey := DM_Utils_Ini(DM_ConfigPath, "AutoFlowState", "OutputKey", "")
    if (sendKey = "")
        return
    Send "{" sendKey "}"
}

AutoFlowState_Run() {
    global DM_ConfigPath, AutoFlowState_Hotkey
    AutoFlowState_Stop()
    DM_Macro_UnregisterModule(AutoFlowState_MODULE)
    if (DM_Utils_Ini(DM_ConfigPath, "AutoFlowState", "Enabled", "0") != "1")
        return
    pressKey := Trim(DM_Utils_Ini(DM_ConfigPath, "AutoFlowState", "Hotkey", ""))
    if (pressKey = "")
        return
    hk := AutoFlowState_ToHotkey(pressKey)
    HotIf (*) => DM_Macro_InRoblox()
    Hotkey hk, AutoFlowState_Fire, "On"
    AutoFlowState_Hotkey := hk
    try HotIf
}
