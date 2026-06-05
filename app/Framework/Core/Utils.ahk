DM_Utils_PathParent(dir) {
    SplitPath dir, , &parent
    return parent
}

DM_Utils_EnsureDir(path) {
    if !DirExist(path)
        DirCreate path
    return path
}

DM_Utils_Ini(path, section, key, default := "") {
    if !FileExist(path)
        return default
    try
        return IniRead(path, section, key, default)
    catch
        return default
}

DM_Utils_IniWrite(path, section, key, value) {
    DM_Utils_EnsureDir(DM_Utils_PathParent(path))
    IniWrite value, path, section, key
}

DM_Utils_Clamp(n, min, max) {
    if (n < min)
        return min
    if (n > max)
        return max
    return n
}

DM_Utils_ScaleForDpi(n) {
    dpi := A_ScreenDPI ? A_ScreenDPI : 96
    return Round(n * dpi / 96)
}

DM_Utils_HexBg(rgb) {
    return Format("{:06X}", rgb & 0xFFFFFF)
}

DM_Utils_AppAssetsDir() {
    return DM_GetFrameworkRoot() "\UI\assets"
}

DM_Utils_AppIconPath() {
    return DM_Utils_AppAssetsDir() "\icon.png"
}

DM_Utils_AppLogoPath() {
    return DM_Utils_AppAssetsDir() "\logo.png"
}

DM_Utils_SetWindowIcon(hwnd, imagePath := "") {
    if !hwnd
        return
    if (imagePath = "")
        imagePath := DM_Utils_AppIconPath()
    if !FileExist(imagePath)
        return
    Loop 2 {
        size := A_Index = 1 ? 32 : 16
        try {
            hIcon := LoadPicture(imagePath, "w" size " h" size, &typ)
            if !hIcon
                continue
            DllCall("SendMessageW", "Ptr", hwnd, "UInt", 0x80, "Ptr", size = 32 ? 1 : 0, "Ptr", hIcon, "Ptr")
        }
    }
}

DM_Utils_TraySetAppIcon(tip := "Macros") {
    path := DM_Utils_AppIconPath()
    ok := false
    if FileExist(path) {
        try {
            TraySetIcon(path, , true)
            ok := true
        }
    }
    if !ok {
        try {
            TraySetIcon("imageres.dll", -104, true)
            ok := true
        } catch {
            TraySetIcon("shell32.dll", 13, true)
        }
    }
    A_IconTip := tip " — left-click tray: open"
}

DM_Utils_RoundFrame(hwnd, radius := 10) {
    if !hwnd
        return
    r := radius < 1 ? 1 : radius
    try {
        roundPref := 2
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 33, "Int*", roundPref, "UInt", 4)
    }
    rect := Buffer(16, 0)
    if !DllCall("user32\GetClientRect", "Ptr", hwnd, "Ptr", rect)
        return
    cw := NumGet(rect, 8, "Int")
    ch := NumGet(rect, 12, "Int")
    if (cw < 2 || ch < 2)
        return
    hrgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", cw + 1, "Int", ch + 1
        , "Int", r * 2, "Int", r * 2, "Ptr")
    if hrgn
        DllCall("user32\SetWindowRgn", "Ptr", hwnd, "Ptr", hrgn, "Int", 1)
}

DM_Utils_SquareFrame(hwnd) => DM_Utils_RoundFrame(hwnd, 0)

DM_Utils_Radius(t := "") {
    return 0
}

DM_Utils_AddNativeBg(gui, x, y, w, h, rgb, borderRgb := "") {
    if (borderRgb != "") {
        bHex := DM_Utils_HexBg(borderRgb)
        fillHex := DM_Utils_HexBg(rgb)
        gui.Add("Text", "x" x " y" y " w" w " h" h " Background" bHex)
        return gui.Add("Text", "x" (x + 1) " y" (y + 1) " w" (w - 2) " h" (h - 2) " Background" fillHex)
    }
    return gui.Add("Text", "x" x " y" y " w" w " h" h " Background" DM_Utils_HexBg(rgb))
}

DM_Utils_AddRoundBg(gui, x, y, w, h, rgb, radius := 8, borderRgb := "", parentRgb := "") {
    return DM_Utils_AddNativeBg(gui, x, y, w, h, rgb, borderRgb)
}

DM_Utils_DragWindow(guiObj, *) {
    PostMessage(0xA1, 2, 0,, guiObj.Hwnd)
}

DM_System_ScreenResolution() {
    return A_ScreenWidth " x " A_ScreenHeight
}

DM_System_MouseSpeed() {
    speed := 0
    if DllCall("SystemParametersInfo", "UInt", 0x70, "UInt", 0, "UInt*", &speed, "UInt", 0)
        return speed
    return 0
}

DM_System_Snapshot() {
    return Map(
        "Resolution", DM_System_ScreenResolution(),
        "MouseSpeed", DM_System_MouseSpeed(),
        "ScreenWidth", A_ScreenWidth,
        "ScreenHeight", A_ScreenHeight
    )
}
