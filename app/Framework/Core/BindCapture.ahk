DM_BindDisplayName(canonical) {
    static names := Map(
        "LButton", "LeftClick",
        "RButton", "RightClick",
        "MButton", "MiddleClick",
        "XButton1", "Mouse Button 4",
        "XButton2", "Mouse Button 5",
        "WheelUp", "Wheel Up",
        "WheelDown", "Wheel Down"
    )
    if (names.Has(canonical))
        return names[canonical]
    return canonical
}

DM_CaptureNextInput(&keyName, timeoutSec := 8) {
    keyName := ""
    state := { captured: "", done: false, hook: 0, ignoreUntil: A_TickCount + 400 }
    ih := InputHook("L" timeoutSec " V")
    ih.KeyOpt("{All}", "N")
    state.hook := ih
    ih.OnKeyDown := DM_CaptureOnKeyDown.Bind(state)

    mouseBtns := ["LButton", "RButton", "MButton", "XButton1", "XButton2", "WheelUp", "WheelDown"]
    for btn in mouseBtns {
        try Hotkey "~*" btn, DM_CaptureMouseHotkey.Bind(state, btn), "On"
    }

    Sleep 200
    ih.Start()

    deadline := A_TickCount + (timeoutSec * 1000)
    while !state.done && A_TickCount < deadline
        Sleep 40

    try ih.Stop()
    for btn in mouseBtns
        try Hotkey "~*" btn, "Off"

    if (state.captured != "")
        keyName := state.captured
    return keyName != ""
}

DM_CaptureOnKeyDown(state, hook, vk, sc) {
    if (state.done)
        return
    name := DM_BindNameFromInput(vk, sc)
    if (name = "Escape") {
        state.done := true
        hook.Stop()
        return
    }
    if (name != "") {
        state.captured := name
        state.done := true
        hook.Stop()
    }
}

DM_CaptureMouseHotkey(state, btn, *) {
    if (state.done || A_TickCount < state.ignoreUntil)
        return
    state.captured := btn
    state.done := true
    if (state.hook)
        try state.hook.Stop()
}

DM_BindNameFromInput(vk, sc) {
    if (vk = 0x1B)
        return "Escape"
    static vkMouse := Map(0x01, "LButton", 0x02, "RButton", 0x04, "MButton", 0x05, "XButton1", 0x06, "XButton2")
    if vkMouse.Has(vk)
        return vkMouse[vk]
    name := ""
    try name := GetKeyName(Format("vk{:02x}", vk))
    if (name = "")
        try name := GetKeyName(Format("sc{:03x}", sc))
    if (name = "" || SubStr(name, 1, 3) = "vk:")
        return ""
    return name
}
