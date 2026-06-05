Assassination_MODULE := "AssassinationDash"
Assassination_ImgsDir() => DM_AppRoot "\imgs\Assassination Dash"

Assassination_AutoEnabled(configPath) {
    auto := DM_Utils_Ini(configPath, "AssassinationDash", "Auto", "")
    if (auto != "")
        return auto = "1"
    return DM_Utils_Ini(configPath, "AssassinationDash", "Enabled", "0") = "1"
}

Assassination_BuildUI(Tab, Win) {
    cfg := Win.ConfigPath
    autoId := "AssassinationDash.Auto"
    Tab.CreateSection("Assassination")
    Win.SetRef(autoId, Tab.CreateToggle({
        Name: "Auto Assassination",
        CurrentValue: Assassination_AutoEnabled(cfg),
        Id: autoId
    }))
    hk := DM_Utils_Ini(cfg, "AssassinationDash", "Hotkey", "")
    Win.SetRef("AssassinationDash.Hotkey", Tab.CreateKeybind({
        Name: "Assassination Keybind",
        Hotkey: hk,
        BindId: "AssassinationDash.Hotkey"
    }))
    dist := Integer(DM_Utils_Ini(cfg, "AssassinationDash", "Distance", "5"))
    if (dist < 1)
        dist := 1
    if (dist > 10)
        dist := 10
    Win.SetRef("AssassinationDash.Distance", Tab.CreateSlider({
        Name: "Distance",
        Range: [1, 10],
        Increment: 1,
        CurrentValue: dist,
        Id: "AssassinationDash.Distance",
        ShowWhen: Map("id", autoId, "value", true)
    }))
}

Assassination_Save(Win, configPath) {
    auto := Win.GetRef("AssassinationDash.Auto")
    if IsObject(auto)
        IniWrite auto.CurrentValue ? "1" : "0", configPath, "AssassinationDash", "Auto"
    dist := Win.GetRef("AssassinationDash.Distance")
    if IsObject(dist)
        IniWrite String(dist.CurrentValue), configPath, "AssassinationDash", "Distance"
    hk := Win.GetRef("AssassinationDash.Hotkey")
    if IsObject(hk)
        IniWrite Trim(hk.Text), configPath, "AssassinationDash", "Hotkey"
}

Assassination_Run() {
    global DM_ConfigPath
    DM_Macro_UnregisterModule(Assassination_MODULE)
}

Assassination_Main(*) {
}
