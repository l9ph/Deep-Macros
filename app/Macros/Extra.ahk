
Extra_DefaultMouseDpi() => "1000"

Extra_AutoFillAtStart(configPath) {
    snap := DM_System_Snapshot()
    DM_Utils_IniWrite(configPath, "System", "ScreenWidth", snap["ScreenWidth"])
    DM_Utils_IniWrite(configPath, "System", "ScreenHeight", snap["ScreenHeight"])
    DM_Utils_IniWrite(configPath, "System", "Resolution", snap["ScreenWidth"] " x " snap["ScreenHeight"])
    DM_Utils_IniWrite(configPath, "System", "WinMouseSpeed", snap["MouseSpeed"])
    if (Extra_ReadMouseDpi(configPath) = "")
        DM_Utils_IniWrite(configPath, "System", "MouseDpi", Extra_DefaultMouseDpi())
    if (DM_Utils_Ini(configPath, "System", "RobloxSensitivity", "") = "")
        DM_Utils_IniWrite(configPath, "System", "RobloxSensitivity", "0.5")
}

Extra_ReadMouseDpi(configPath) {
    v := DM_Utils_Ini(configPath, "System", "MouseDpi", "")
    if (v != "")
        return v
    legacy := DM_Utils_Ini(configPath, "System", "Dpi", "")
    if (legacy != "" && Integer(legacy) > 200)
        return legacy
    return ""
}

Extra_ReadScreenSize(configPath, snap) {
    w := DM_Utils_Ini(configPath, "System", "ScreenWidth", "")
    h := DM_Utils_Ini(configPath, "System", "ScreenHeight", "")
    if (w != "" && h != "")
        return Map("w", w, "h", h)
    res := DM_Utils_Ini(configPath, "System", "Resolution", "")
    if (res != "" && RegExMatch(res, "(\d+)\s*[xX×]\s*(\d+)", &m))
        return Map("w", m[1], "h", m[2])
    return Map("w", snap["ScreenWidth"], "h", snap["ScreenHeight"])
}

Extra_BuildUI(Tab, Win) {
    cfg := Win.ConfigPath
    vals := Extra_LoadConfigValues(cfg)
    size := Extra_ReadScreenSize(cfg, DM_System_Snapshot())

    Tab.CreateSection("Settings")
    res := Win.app.WebCreateResolution("Resolution", size["w"], size["h"], "System.ScreenWidth", "System.ScreenHeight")
    Win.SetRef("System.ScreenWidth", res["w"])
    Win.SetRef("System.ScreenHeight", res["h"])
    Win.SetRef("System.MouseDpi", Tab.CreateInput({
        Name: "DPI",
        CurrentValue: vals["MouseDpi"],
        PlaceholderText: "1000"
    }))
    Win.SetRef("System.WinMouseSpeed", Tab.CreateInput({
        Name: "Windows mouse speed",
        CurrentValue: vals["WinMouseSpeed"],
        PlaceholderText: "1-20"
    }))
    Win.SetRef("System.RobloxSensitivity", Tab.CreateInput({
        Name: "Roblox sensitivity",
        CurrentValue: vals["RobloxSensitivity"],
        PlaceholderText: "e.g. 0.5"
    }))

    Tab.CreateHint("Version: " DM_AppVersion())

    Tab.CreateSection("Bootstrap (test)")
    Tab.CreateHint("Si ves el botón de abajo, el sync desde GitHub funcionó.")
    Tab.CreateButton({ Name: "✓ Bootstrap OK · v1.8.1" })
}

Extra_LoadConfigValues(configPath) {
    snap := DM_System_Snapshot()
    size := Extra_ReadScreenSize(configPath, snap)
    mouseDpi := Extra_ReadMouseDpi(configPath)
    if (mouseDpi = "")
        mouseDpi := Extra_DefaultMouseDpi()
    ms := DM_Utils_Ini(configPath, "System", "WinMouseSpeed", "")
    if (ms = "")
        ms := snap["MouseSpeed"]
    rbx := DM_Utils_Ini(configPath, "System", "RobloxSensitivity", "")
    if (rbx = "")
        rbx := "0.5"
    return Map(
        "ScreenWidth", size["w"],
        "ScreenHeight", size["h"],
        "MouseDpi", mouseDpi,
        "WinMouseSpeed", ms,
        "RobloxSensitivity", rbx
    )
}

Extra_Save(Win, configPath) {
    refW := Win.GetRef("System.ScreenWidth")
    refH := Win.GetRef("System.ScreenHeight")
    if IsObject(refW) && IsObject(refH) {
        w := Trim(refW.Text)
        h := Trim(refH.Text)
        DM_Utils_IniWrite(configPath, "System", "ScreenWidth", w)
        DM_Utils_IniWrite(configPath, "System", "ScreenHeight", h)
        DM_Utils_IniWrite(configPath, "System", "Resolution", w " x " h)
    }
    refDpi := Win.GetRef("System.MouseDpi")
    if IsObject(refDpi)
        DM_Utils_IniWrite(configPath, "System", "MouseDpi", Trim(refDpi.Text))
    refMs := Win.GetRef("System.WinMouseSpeed")
    if IsObject(refMs)
        DM_Utils_IniWrite(configPath, "System", "WinMouseSpeed", Trim(refMs.Text))
    refRbx := Win.GetRef("System.RobloxSensitivity")
    if IsObject(refRbx)
        DM_Utils_IniWrite(configPath, "System", "RobloxSensitivity", Trim(refRbx.Text))
}

Extra_GetSystem(configPath) {
    vals := Extra_LoadConfigValues(configPath)
    return Map(
        "Resolution", vals["ScreenWidth"] " x " vals["ScreenHeight"],
        "ScreenWidth", Integer(vals["ScreenWidth"]),
        "ScreenHeight", Integer(vals["ScreenHeight"]),
        "MouseDpi", Integer(vals["MouseDpi"]),
        "WinMouseSpeed", Integer(vals["WinMouseSpeed"]),
        "RobloxSensitivity", vals["RobloxSensitivity"]
    )
}
