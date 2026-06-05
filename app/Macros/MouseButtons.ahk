global MouseButtons_Hotkeys := []
global MouseButtons_SendMap := Map()

MouseButtons_LoadEntries(configPath) {
    entries := []
    count := Integer(DM_Utils_Ini(configPath, "MouseButtons", "Count", "0"))
    if (count < 1)
        return [Map("trigger", "", "send", "")]
    Loop count {
        i := A_Index
        sec := "MouseButtons_" i
        entries.Push(Map(
            "trigger", DM_Utils_Ini(configPath, sec, "Trigger", ""),
            "send", DM_Utils_Ini(configPath, sec, "Send", "")
        ))
    }
    return entries
}

MouseButtons_BuildUI(Tab, Win) {
    cfg := Win.ConfigPath
    Tab.CreateSection("Mouse Tweaks")
    Win.SetRef("MouseButtons.Enabled", Tab.CreateToggle({
        Name: "Enabled",
        CurrentValue: DM_Utils_Ini(cfg, "MouseButtons", "Enabled", "1") = "1"
    }))
    Tab.CreateMappingList({
        ListId: "MouseButtons",
        Entries: MouseButtons_LoadEntries(cfg)
    })
}

MouseButtons_Save(Win, configPath) {
    global DM_ActiveApp
    t := Win.GetRef("MouseButtons.Enabled")
    if IsObject(t)
        IniWrite t.CurrentValue ? "1" : "0", configPath, "MouseButtons", "Enabled"
    entries := []
    if (IsObject(DM_ActiveApp) && DM_ActiveApp.HasProp("_mappingLists")
        && DM_ActiveApp._mappingLists.Has("MouseButtons"))
        entries := DM_ActiveApp._mappingLists["MouseButtons"]
    if !entries.Length
        entries := [Map("trigger", "", "send", "")]
    IniWrite entries.Length, configPath, "MouseButtons", "Count"
    for i, row in entries {
        IniWrite row["trigger"], configPath, "MouseButtons_" i, "Trigger"
        IniWrite row["send"], configPath, "MouseButtons_" i, "Send"
    }
}

MouseButtons_Stop() {
    global MouseButtons_Hotkeys
    for hk in MouseButtons_Hotkeys
        try Hotkey hk, "Off"
    MouseButtons_Hotkeys := []
    MouseButtons_SendMap.Clear()
    try HotIf
}

MouseButtons_ToHotkey(key) {
    k := Trim(key)
    if RegExMatch(k, "i)^(LButton|RButton|MButton|XButton\d*|Wheel(?:Up|Down))$")
        return "$" k
    return k
}

MouseButtons_KeyFromHotkey(hk) {
    return RegExReplace(hk, "^[\~\$]+", "")
}

MouseButtons_InRoblox() {
    return WinActive("ahk_exe RobloxPlayerBeta.exe")
        || WinActive("ahk_exe RobloxPlayer.exe")
        || WinActive("ahk_class RobloxApp")
        || WinActive("Roblox")
}

MouseButtons_Fire(*) {
    global MouseButtons_SendMap
    if !MouseButtons_InRoblox()
        return
    pressKey := MouseButtons_KeyFromHotkey(A_ThisHotkey)
    if !MouseButtons_SendMap.Has(pressKey)
        return
    sendKey := MouseButtons_SendMap[pressKey]
    if (sendKey = "")
        return
    Send "{" sendKey "}"
}

MouseButtons_Run() {
    global DM_ConfigPath
    MouseButtons_Stop()
    if (DM_Utils_Ini(DM_ConfigPath, "MouseButtons", "Enabled", "0") != "1")
        return

    count := Integer(DM_Utils_Ini(DM_ConfigPath, "MouseButtons", "Count", "0"))
    HotIf (*) => DM_Macro_InRoblox()
    Loop count {
        i := A_Index
        pressKey := Trim(DM_Utils_Ini(DM_ConfigPath, "MouseButtons_" i, "Trigger", ""))
        sendKey := Trim(DM_Utils_Ini(DM_ConfigPath, "MouseButtons_" i, "Send", ""))
        if (pressKey = "" || sendKey = "")
            continue
        MouseButtons_SendMap[pressKey] := sendKey
        hk := MouseButtons_ToHotkey(pressKey)
        if (hk = "")
            continue
        Hotkey hk, MouseButtons_Fire, "On"
        MouseButtons_Hotkeys.Push(hk)
    }
    try HotIf
}
